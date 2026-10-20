"""
Mô hình chọn waypoint theo đường (path-based): mỗi demand ở mỗi thời kỳ chọn đúng một phương án trong
W[d] = {không waypoint} ∪ {1 waypoint ∈ C[d]} ∪ {cặp (w1,w2) từ K2 ứng viên đầu}. Với K = n-2 và K2 = 0 đây là
bài toán gốc khi maxSeg = 2 (chính xác); với K2 = n-2 là khi maxSeg = 3; với maxSeg lớn hơn đây là bài toán
hạn chế (cận trên của bài toán gốc). Kích thước: |D|·P·|W[d]| biến thay vì |D|·P·n(n-1).
"""

"Ứng viên waypoint: 0 và tối đa K nút có độ vòng D[s,w]+D[w,t]-D[s,t] nhỏ nhất, hợp lệ ở mọi thời kỳ."
function candidates(inst::Instance, rs, K::Int)
    D = routing(inst, 1).D
    P = length(rs)
    C = Vector{Vector{Int}}(undef, length(inst.dem_s))
    for d in eachindex(inst.dem_s)
        s, t = inst.dem_s[d], inst.dem_t[d]
        ws = [w for w in 1:inst.n if w != s && w != t &&
              all(p -> haskey(rs[p], (s, w)) && haskey(rs[p], (w, t)), 1:P)]
        sort!(ws, by=w -> (D[s, w] + D[w, t] - D[s, t], w))
        C[d] = vcat(0, ws[1:min(K, length(ws))])
    end
    return C
end

"Giữ lại các waypoint hợp lệ ở MỌI thời kỳ (có đường s->w và w->t trong mỗi G_t); 0 (không waypoint) luôn được giữ."
function filter_cands(inst::Instance, rs, C)
    P = length(rs)
    return [[w for w in C[d] if w == 0 || all(p -> haskey(rs[p], (inst.dem_s[d], w)) && haskey(rs[p], (w, inst.dem_t[d])), 1:P)]
            for d in eachindex(C)]
end

wp_seq(inst, d, wl) = vcat(inst.dem_s[d], wl, inst.dem_t[d])

function build_wp_model(inst::Instance, rs, P::Int, optimizer; K::Int=20, K2::Int=0, tlimit=Inf, silent=true,
                        eps=nothing, start_paths=nothing, cands=nothing, ucap=nothing, freeze=Int[])
    nD = length(inst.dem_s)
    eps = eps === nothing ? 1e-7 / nD : eps
    C = cands === nothing ? candidates(inst, rs, K) : cands
    valid(sq) = all(p -> all(haskey(rs[p], sg) for sg in zip(sq, sq[2:end])), 1:P)

    # W[d][c]: danh sách waypoint của phương án c (c = 1: không waypoint)
    W = Vector{Vector{Vector{Int}}}(undef, nD)
    for d in 1:nD
        ws = [w for w in C[d] if w != 0]
        lst = vcat([Int[]], [[w] for w in ws])
        top = ws[1:min(K2, length(ws))]
        for a in top, b in top
            a != b && valid(wp_seq(inst, d, [a, b])) && push!(lst, [a, b])
        end
        W[d] = lst
    end
    if start_paths !== nothing            # phương án của nghiệm khởi tạo luôn có mặt (nếu hợp lệ ở mọi thời kỳ)
        for d in 1:nD, p in 1:P
            wl = start_paths[(d, p)][2:end-1]
            length(wl) <= 2 && !(wl in W[d]) && valid(wp_seq(inst, d, wl)) && push!(W[d], wl)
        end
    end

    model = Model(optimizer)
    silent && set_silent(model)
    isfinite(tlimit) && set_time_limit_sec(model, tlimit)

    y = [[@variable(model, [1:length(W[d])], Bin) for p in 1:P] for d in 1:nD]
    @variable(model, z >= 0)

    assign = [[@constraint(model, sum(y[d][p]) == 1) for p in 1:P] for d in 1:nD]
    loadcon = [Dict{Int,Any}() for _ in 1:P]

    # tải: mỗi phương án đóng góp r(đoạn)·lưu lượng trên từng đoạn của đường
    for p in 1:P
        load = [AffExpr(0.0) for _ in 1:inst.m]
        for d in 1:nD
            v = inst.vol[d, p]
            v == 0 && continue
            for (c, wl) in enumerate(W[d])
                sq = wp_seq(inst, d, wl)
                for (u, t) in zip(sq, sq[2:end]), (a, fr) in rs[p][(u, t)]
                    add_to_expression!(load[a], fr * v, y[d][p][c])
                end
            end
        end
        for a in 1:inst.m
            a in inst.down[p] && continue
            # ucap[p][a] hữu hạn: cung đã bị "đóng băng" ở mức tải tối đa đó
            level = (ucap === nothing || !isfinite(ucap[p][a])) ? z : ucap[p][a]
            loadcon[p][a] = @constraint(model, load[a] <= inst.cap[a] * level)
        end
    end

    # ngân sách: dist = Σ_đoạn |g_p(đoạn) - g_{p-1}(đoạn)|, với g(đoạn) = Σ phương án chứa đoạn đó (0/1)
    for p in 2:P
        isfinite(inst.budget[p]) || continue
        total = AffExpr(0.0)
        compact = all(length(wl) <= 1 for d in 1:nD for wl in W[d])
        if compact
            # chỉ có {không waypoint, 1 waypoint}: dist giữa hai phương án = 0 (giống), 3 (một bên không waypoint),
            # 4 (hai waypoint khác nhau) => change_d = 4 - 4*Σ_c st_c - (y1_none + y2_none - 2*st_none),
            # với st_c <= min(y1_c, y2_c). Công thức gọn, LP chặt hơn công thức theo đoạn.
            for d in 1:nD
                st = @variable(model, [1:length(W[d])], lower_bound = 0, upper_bound = 1)
                for c in 1:length(W[d])
                    @constraint(model, st[c] <= y[d][p-1][c])
                    @constraint(model, st[c] <= y[d][p][c])
                    add_to_expression!(total, -4.0, st[c])
                end
                add_to_expression!(total, 4.0)
                add_to_expression!(total, -1.0, y[d][p-1][1])     # c = 1: không waypoint
                add_to_expression!(total, -1.0, y[d][p][1])
                add_to_expression!(total, 2.0, st[1])
            end
            @constraint(model, total <= inst.budget[p])
            continue
        end
        for d in 1:nD
            segs_of = Dict{Tuple{Int,Int},Vector{Int}}()
            for (c, wl) in enumerate(W[d])
                sq = wp_seq(inst, d, wl)
                for sg in zip(sq, sq[2:end])
                    push!(get!(segs_of, sg, Int[]), c)
                end
            end
            for (_, cs) in segs_of
                u = @variable(model, lower_bound = 0)
                g1 = sum(y[d][p-1][c] for c in cs)
                g2 = sum(y[d][p][c] for c in cs)
                @constraint(model, u >= g2 - g1)
                @constraint(model, u >= g1 - g2)
                add_to_expression!(total, 1.0, u)
            end
        end
        @constraint(model, total <= inst.budget[p])
    end

    # ưu tiên ít waypoint khi cùng MLU
    @objective(model, Min, z + eps * sum(length(W[d][c]) * y[d][p][c] for d in 1:nD, p in 1:P, c in 1:length(W[d])))

    if start_paths !== nothing
        for d in 1:nD, p in 1:P
            c = findfirst(==(start_paths[(d, p)][2:end-1]), W[d])
            c === nothing && (c = 1)
            for k in 1:length(W[d])
                set_start_value(y[d][p][k], k == c ? 1.0 : 0.0)
            end
        end
    end
    if !isempty(freeze)               # demand bị đóng băng giữ nguyên lựa chọn của start_paths (dùng cho LNS)
        start_paths === nothing && error("freeze requires start_paths")
        for d in freeze, p in 1:P
            c = findfirst(==(start_paths[(d, p)][2:end-1]), W[d])
            c === nothing && continue
            for k in 1:length(W[d])
                fix(y[d][p][k], k == c ? 1.0 : 0.0; force=true)
            end
        end
    end
    model[:assign] = assign                  # tham chiếu ràng buộc, dùng để lấy đối ngẫu (sinh cột)
    model[:loadcon] = loadcon
    return model, y, W
end

function extract_wp_paths(inst::Instance, y, W, P::Int)
    paths = Dict{Tuple{Int,Int},Vector{Int}}()
    for d in eachindex(inst.dem_s), p in 1:P
        c = argmax([value(v) for v in y[d][p]])
        paths[(d, p)] = wp_seq(inst, d, W[d][c])
    end
    return paths
end

"""
Sinh cột cho mô hình waypoint (chỉ một waypoint). Lặp: giải LP của mô hình thu gọn, lấy đối ngẫu λ của các ràng
buộc tải và μ của ràng buộc gán, định giá mọi waypoint w của mỗi demand bằng chi phí rút gọn
rc = eps + δ(d,p)·(g_p(s,w) + g_p(w,τ)) − μ(d,p), với g_p(u,v) = Σ_a λ(a,p)·r(u,v,a,p), rồi thêm các w có rc < 0.
Tham số `extra`: sau khi hội tụ, thêm tối đa `extra` cột chi phí rút gọn thấp nhất cho mỗi demand (làm giàu).
Trả về (C, lp, iters): tập ứng viên, giá trị LP cuối và số vòng lặp. Với P = 1, khi hội tụ `lp` là cận dưới hợp lệ
của bài toán một waypoint. Với P > 1 ngân sách không được đưa vào bước định giá (chỉ để chọn ứng viên).
"""
function colgen(inst::Instance, rs, P::Int; K0::Int=3, add_per_demand::Int=3, max_iter::Int=50, tol::Float64=1e-9, extra::Int=0)
    nD = length(inst.dem_s)
    eps = 1e-7 / nD
    allw = candidates(inst, rs, inst.n)             # mọi waypoint hợp lệ của từng demand (phần tử đầu là 0)
    C = candidates(inst, rs, K0)
    lp = NaN
    iters = 0
    for it in 1:max_iter
        iters = it
        opt = optimizer_with_attributes(HiGHS.Optimizer, "threads" => 1)
        model, y, W = build_wp_model(inst, rs, P, opt; cands=C)
        relax_integrality(model)
        optimize!(model)
        lp = objective_value(model)
        lam = [zeros(inst.m) for _ in 1:P]
        for p in 1:P, (a, con) in model[:loadcon][p]
            lam[p][a] = max(0.0, -dual(con))
        end
        memo = [Dict{Tuple{Int,Int},Float64}() for _ in 1:P]
        g(p, u, v) = get!(memo[p], (u, v)) do
            sum(lam[p][a] * fr for (a, fr) in rs[p][(u, v)]; init=0.0)
        end
        added = 0
        pending = [Tuple{Float64,Int}[] for _ in 1:nD]       # các cột chi phí rút gọn thấp nhất (để làm giàu)
        for d in 1:nD
            s, t = inst.dem_s[d], inst.dem_t[d]
            inC = Set(C[d])
            scored = Tuple{Float64,Int}[]
            for w in allw[d]
                (w == 0 || w in inC) && continue
                rc = minimum(eps + inst.vol[d, p] * (g(p, s, w) + g(p, w, t)) - dual(model[:assign][d][p]) for p in 1:P)
                push!(scored, (rc, w))
            end
            sort!(scored)
            extra > 0 && (pending[d] = scored[1:min(extra, length(scored))])
            for (rc, w) in scored[1:min(add_per_demand, length(scored))]
                rc < -tol || break
                push!(C[d], w)
                added += 1
            end
        end
        if added == 0
            # hội tụ: làm giàu thêm `extra` cột chi phí rút gọn thấp nhất mỗi demand để MILP có nhiều lựa chọn nguyên
            for d in 1:nD, (_, w) in pending[d]
                w in C[d] || push!(C[d], w)
            end
            break
        end
    end
    return C, lp, iters
end

"""
Heuristic đóng băng các cung đang chạm mức tải hiện tại rồi giải lại trên các cung còn lại.
Đây không phải tối ưu từ điển chính xác; dùng `exact_lexicographic_loads!` cho yêu cầu đó.
"""
function load_freezing_refine(inst::Instance, rs, P::Int, optimizer; K::Int=20, cands=nothing, levels::Int=5,
                    tlimit=Inf, start_paths=nothing)
    vec(paths) = sort(vcat([utilization(inst, rs, paths, p)[[a for a in 1:inst.m if !(a in inst.down[p])]] for p in 1:P]...); rev=true)
    ucap = [fill(Inf, inst.m) for _ in 1:P]
    best = start_paths
    cur = start_paths
    done = 0
    for lv in 1:levels
        model, y, W = build_wp_model(inst, rs, P, optimizer; K=K, cands=cands, tlimit=tlimit, start_paths=cur, ucap=ucap)
        optimize!(model)
        has_values(model) || break
        cur = extract_wp_paths(inst, y, W, P)
        done = lv
        (best === nothing || lex_leq(vec(cur), vec(best))) && (best = cur)
        u = [utilization(inst, rs, cur, p) for p in 1:P]
        free = [(p, a) for p in 1:P for a in 1:inst.m if !(a in inst.down[p]) && !isfinite(ucap[p][a])]
        isempty(free) && break
        zk = maximum(u[p][a] for (p, a) in free)
        zk <= 1e-9 && break
        tight = [(p, a) for (p, a) in free if u[p][a] >= zk - 1e-7 * max(1.0, zk)]
        for (p, a) in tight
            ucap[p][a] = zk * (1 + 1e-9) + 1e-12
        end
        length(tight) == length(free) && break
    end
    return best, done
end
