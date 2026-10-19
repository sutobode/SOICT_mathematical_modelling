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

wp_seq(inst, d, wl) = vcat(inst.dem_s[d], wl, inst.dem_t[d])

function build_wp_model(inst::Instance, rs, P::Int, optimizer; K::Int=20, K2::Int=0, tlimit=Inf, silent=true,
                        eps=nothing, start_paths=nothing, cands=nothing)
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

    for d in 1:nD, p in 1:P
        @constraint(model, sum(y[d][p]) == 1)
    end

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
            @constraint(model, load[a] <= inst.cap[a] * z)
        end
    end

    # ngân sách: dist = Σ_đoạn |g_p(đoạn) - g_{p-1}(đoạn)|, với g(đoạn) = Σ phương án chứa đoạn đó (0/1)
    for p in 2:P
        isfinite(inst.budget[p]) || continue
        total = AffExpr(0.0)
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
