function build_model(inst::Instance, rs, P::Int, optimizer;
                     tlimit=Inf, silent=true, eps=1e-7, warm_start=true)
    n, nD = inst.n, length(inst.dem_s)
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
    ys = []
    for p in 2:P
        isfinite(inst.budget[p]) || continue
        y = @variable(model, [d=1:nD, i=1:n, j=1:n; i != j], lower_bound = 0)
        push!(ys, y)
        for d in 1:nD, i in 1:n, j in 1:n
            i == j && continue
            @constraint(model, y[d, i, j] >= x[d, p, i, j] - x[d, p-1, i, j])
            @constraint(model, y[d, i, j] >= x[d, p-1, i, j] - x[d, p, i, j])
        end
        @constraint(model, sum(y[d, i, j] for d in 1:nD, i in 1:n, j in 1:n if i != j) <= inst.budget[p])
    end

    @objective(model, Min, z + eps * sum(x))

    # khởi tạo bằng nghiệm "đi thẳng" (luôn khả thi: dist = 0)
    if warm_start && all(haskey(rs[p], (inst.dem_s[d], inst.dem_t[d])) for d in 1:nD, p in 1:P)
        for d in 1:nD, p in 1:P, i in 1:n, j in 1:n
            i == j && continue
            set_start_value(x[d, p, i, j], (i == inst.dem_s[d] && j == inst.dem_t[d]) ? 1.0 : 0.0)
        end
        set_start_value(z, base_mlu(inst, rs, P))
        for y in ys, v in y
            set_start_value(v, 0.0)
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
