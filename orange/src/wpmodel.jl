"""
Mô hình chọn waypoint theo đường (path-based): mỗi demand ở mỗi thời kỳ chọn đúng một phương án
trong C[d] = {0 (không waypoint)} ∪ {≤ K waypoint ứng viên}. Tương ứng chính xác với bài toán gốc khi
maxSeg = 2 và K đủ lớn; với maxSeg > 2 đây là bài toán hạn chế (cận trên). Kích thước: |D|·P·(K+1) biến
thay vì |D|·P·n(n-1).
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

path_of(inst, d, w) = w == 0 ? [inst.dem_s[d], inst.dem_t[d]] : [inst.dem_s[d], w, inst.dem_t[d]]

function build_wp_model(inst::Instance, rs, P::Int, optimizer; K::Int=20, tlimit=Inf, silent=true,
                        eps=nothing, start_paths=nothing, cands=nothing)
    nD = length(inst.dem_s)
    eps = eps === nothing ? 1e-7 / nD : eps
    C = cands === nothing ? candidates(inst, rs, K) : cands
    model = Model(optimizer)
    silent && set_silent(model)
    isfinite(tlimit) && set_time_limit_sec(model, tlimit)

    y = [[@variable(model, [1:length(C[d])], Bin) for p in 1:P] for d in 1:nD]
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
            for (c, w) in enumerate(C[d])
                seq = path_of(inst, d, w)
                for (u, t) in zip(seq, seq[2:end]), (a, fr) in rs[p][(u, t)]
                    add_to_expression!(load[a], fr * v, y[d][p][c])
                end
            end
        end
        for a in 1:inst.m
            a in inst.down[p] && continue
            @constraint(model, load[a] <= inst.cap[a] * z)
        end
    end

    # ngân sách: dist giữa hai phương án = 0 (giống nhau), 3 (một bên không waypoint), 4 (hai waypoint khác nhau)
    # change_d = 4 - 4*Σ_c st_c - (y1_none + y2_none - 2*st_none), st_c <= min(y1_c, y2_c)
    for p in 2:P
        isfinite(inst.budget[p]) || continue
        total = AffExpr(0.0)
        for d in 1:nD
            st = @variable(model, [1:length(C[d])], lower_bound = 0, upper_bound = 1)
            for c in 1:length(C[d])
                @constraint(model, st[c] <= y[d][p-1][c])
                @constraint(model, st[c] <= y[d][p][c])
            end
            add_to_expression!(total, 4.0)
            for c in 1:length(C[d])
                add_to_expression!(total, -4.0, st[c])
            end
            add_to_expression!(total, -1.0, y[d][p-1][1])    # c = 1 là phương án "không waypoint"
            add_to_expression!(total, -1.0, y[d][p][1])
            add_to_expression!(total, 2.0, st[1])
        end
        @constraint(model, total <= inst.budget[p])
    end

    @objective(model, Min, z + eps * sum(1 - y[d][p][1] for d in 1:nD, p in 1:P))

    if start_paths !== nothing
        for d in 1:nD, p in 1:P
            seq = start_paths[(d, p)]
            w = length(seq) == 2 ? 0 : seq[2]
            c = findfirst(==(w), C[d])
            c === nothing && (c = 1)
            for k in 1:length(C[d])
                set_start_value(y[d][p][k], k == c ? 1.0 : 0.0)
            end
        end
    end
    return model, y, C
end

function extract_wp_paths(inst::Instance, y, C, P::Int)
    paths = Dict{Tuple{Int,Int},Vector{Int}}()
    for d in eachindex(inst.dem_s), p in 1:P
        c = argmax([value(v) for v in y[d][p]])
        paths[(d, p)] = path_of(inst, d, C[d][c])
    end
    return paths
end
