function build_model(inst::Instance, rs, P::Int, optimizer;
                     tlimit=Inf, silent=true, eps=nothing, warm_start=true, acyclic=false, start_paths=nothing)
    n, nD = inst.n, length(inst.dem_s)
    eps = eps === nothing ? 1e-7 / nD : eps               # tổng phạt eps*sum(x) <= ~1e-7*maxSeg*P
    model = Model(optimizer)
    silent && set_silent(model)
    isfinite(tlimit) && set_time_limit_sec(model, tlimit)

    @variable(model, x[d=1:nD, p=1:P, i=1:n, j=1:n; i != j], Bin)
    @variable(model, z >= 0)

    # đoạn không có đường trong G_p bị cấm
    for p in 1:P, i in 1:n, j in 1:n
        (i == j || haskey(rs[p], (i, j))) && continue
        for d in 1:nD
            fix(x[d, p, i, j], 0.0; force=true)
        end
    end

    # demand có lưu lượng 0 ở mọi thời kỳ: đi thẳng (không ảnh hưởng tải, dist = 0)
    for d in 1:nD
        all(iszero, inst.vol[d, 1:P]) || continue
        s, t = inst.dem_s[d], inst.dem_t[d]
        all(p -> haskey(rs[p], (s, t)), 1:P) || continue
        for p in 1:P, i in 1:n, j in 1:n
            i == j && continue
            fix(x[d, p, i, j], (i == s && j == t) ? 1.0 : 0.0; force=true)
        end
    end

    # (1) bảo toàn luồng
    for d in 1:nD, p in 1:P, i in 1:n
        rhs = i == inst.dem_s[d] ? 1 : (i == inst.dem_t[d] ? -1 : 0)
        @constraint(model, sum(x[d, p, i, j] for j in 1:n if j != i) -
                           sum(x[d, p, j, i] for j in 1:n if j != i) == rhs)
    end

    # mỗi nút có tối đa một đoạn vào và một đoạn ra: đường đơn (+ chu trình rời)
    for d in 1:nD, p in 1:P, i in 1:n
        @constraint(model, sum(x[d, p, i, j] for j in 1:n if j != i) <= 1)
        @constraint(model, sum(x[d, p, j, i] for j in 1:n if j != i) <= 1)
    end

    # (tùy chọn) loại hẳn chu trình rời bằng thứ tự MTZ: x_ij = 1 => u_j >= u_i + 1
    if acyclic
        M = inst.maxseg + 1
        u = @variable(model, [d=1:nD, p=1:P, i=1:n], lower_bound = 0, upper_bound = inst.maxseg)
        for d in 1:nD, p in 1:P, i in 1:n, j in 1:n
            i == j && continue
            (is_fixed(x[d, p, i, j]) && fix_value(x[d, p, i, j]) == 0.0) && continue
            @constraint(model, u[d, p, j] >= u[d, p, i] + 1 - M * (1 - x[d, p, i, j]))
        end
    end

    # (2) số đoạn
    for d in 1:nD, p in 1:P
        @constraint(model, sum(x[d, p, i, j] for i in 1:n, j in 1:n if i != j) <= inst.maxseg)
    end

    # (3) tải, z là MLU
    load = [[AffExpr(0.0) for _ in 1:inst.m] for _ in 1:P]
    for p in 1:P
        for ((i, j), lst) in rs[p], (a, fr) in lst, d in 1:nD
            c = fr * inst.vol[d, p]
            c == 0 && continue
            add_to_expression!(load[p][a], c, x[d, p, i, j])
        end
        for a in 1:inst.m
            a in inst.down[p] && continue
            @constraint(model, load[p][a] <= inst.cap[a] * z)
        end
    end

    # (4) ngân sách giữa p-1 và p
    ys = Tuple{Int,Any}[]
    for p in 2:P
        isfinite(inst.budget[p]) || continue
        y = @variable(model, [d=1:nD, i=1:n, j=1:n; i != j], lower_bound = 0)
        push!(ys, (p, y))
        for d in 1:nD, i in 1:n, j in 1:n
            i == j && continue
            @constraint(model, y[d, i, j] >= x[d, p, i, j] - x[d, p-1, i, j])
            @constraint(model, y[d, i, j] >= x[d, p-1, i, j] - x[d, p, i, j])
        end
        @constraint(model, sum(y[d, i, j] for d in 1:nD, i in 1:n, j in 1:n if i != j) <= inst.budget[p])
    end

    @objective(model, Min, z + eps * sum(x))

    # khởi tạo bằng start_paths (mặc định: "đi thẳng", luôn khả thi vì dist = 0)
    sp = start_paths === nothing ? direct_paths(inst, P) : start_paths
    if warm_start && all(haskey(rs[p], (inst.dem_s[d], inst.dem_t[d])) for d in 1:nD, p in 1:P)
        on(d, p) = Set(zip(sp[(d, p)], sp[(d, p)][2:end]))
        for d in 1:nD, p in 1:P
            S = on(d, p)
            for i in 1:n, j in 1:n
                i == j && continue
                set_start_value(x[d, p, i, j], (i, j) in S ? 1.0 : 0.0)
            end
        end
        set_start_value(z, max_utilization(inst, rs, sp, P))
        for (p, y) in ys, d in 1:nD
            S0, S1 = on(d, p - 1), on(d, p)
            for i in 1:n, j in 1:n
                i == j && continue
                set_start_value(y[d, i, j], ((i, j) in S0) != ((i, j) in S1) ? 1.0 : 0.0)
            end
        end
    end
    return model, x, z, load
end

"Đường s -> τ trên các đoạn được chọn (BFS, bỏ qua chu trình rời)."
function extract_paths(inst::Instance, x, P::Int; val=value)
    n = inst.n
    paths = Dict{Tuple{Int,Int},Vector{Int}}()
    for d in eachindex(inst.dem_s), p in 1:P
        s, t = inst.dem_s[d], inst.dem_t[d]
        succ = [Int[] for _ in 1:n]
        for i in 1:n, j in 1:n
            i != j && val(x[d, p, i, j]) > 0.5 && push!(succ[i], j)
        end
        prev = zeros(Int, n)
        prev[s] = s
        queue = [s]
        while !isempty(queue)
            u = popfirst!(queue)
            u == t && break
            for v in succ[u]
                prev[v] == 0 || continue
                prev[v] = u
                push!(queue, v)
            end
        end
        prev[t] == 0 && error("no s-t path for demand $d period $p")
        seq = [t]
        while seq[1] != s
            pushfirst!(seq, prev[seq[1]])
        end
        paths[(d, p)] = seq
    end
    return paths
end

"Giai đoạn 2 của lex-min: giữ z <= z*, tối thiểu tổng tải (mức thứ hai của thứ tự từ điển)."
function lex_second_stage!(model, z, load, inst::Instance, zstar::Real)
    @constraint(model, z <= zstar * (1 + 1e-6) + 1e-9)
    @objective(model, Min, sum(load[p][a] / inst.cap[a] for p in eachindex(load), a in 1:inst.m
                               if !(a in inst.down[p])))
    return model
end
