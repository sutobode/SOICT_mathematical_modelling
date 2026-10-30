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

"Optional total-load tie-breaker under an MLU tolerance; this is not lexicographic optimization."
function total_load_second_stage!(model, z, load, inst::Instance, zstar::Real)
    @constraint(model, z <= zstar * (1 + 1e-6) + 1e-9)
    @objective(model, Min, sum(load[p][a] / inst.cap[a] for p in eachindex(load), a in 1:inst.m
                               if !(a in inst.down[p])))
    return model
end

function _variable_interval(v)
    if is_fixed(v)
        x = fix_value(v)
        return x, x
    end
    lo = is_binary(v) ? 0.0 : (has_lower_bound(v) ? lower_bound(v) : -Inf)
    hi = is_binary(v) ? 1.0 : (has_upper_bound(v) ? upper_bound(v) : Inf)
    return lo, hi
end

"A finite, outward-rounded interval containing every value of an affine expression."
function _affine_interval(expr)
    lo = hi = Float64(constant(expr))
    for (coef, var) in linear_terms(expr)
        vlo, vhi = _variable_interval(var)
        isfinite(vlo) && isfinite(vhi) || error("lexicographic loads require bounded variables")
        p, q = Float64(coef) * vlo, Float64(coef) * vhi
        tlo, thi = prevfloat(min(p, q)), nextfloat(max(p, q))
        lo, hi = prevfloat(lo + tlo), nextfloat(hi + thi)
    end
    isfinite(lo) && isfinite(hi) || error("could not derive a finite load bound")
    return lo, hi
end

"""
    exact_lexicographic_loads!(model, load, inst)

Exactly minimize, in lexicographic order, the decreasingly sorted vector of
utilizations of all active physical links in `load`. The routine adds a binary
assignment sorting formulation, then minimizes one rank at a time and fixes
each proven optimum before solving the next rank. It replaces the model's
current objective and requires an optimal solver status at every rank.

The sorting big-M is not a user-chosen constant: it is obtained from finite
variable bounds in the supplied affine load expressions using outward-rounded
interval arithmetic. Returns the final values and the added JuMP references.
"""
function exact_lexicographic_loads!(model::Model, load, inst::Instance)
    length(load) <= inst.P || error("load has more periods than the instance")
    active = [(p, a) for p in eachindex(load), a in 1:inst.m if !(a in inst.down[p])]
    all(length(load[p]) == inst.m for p in eachindex(load)) || error("load dimensions do not match the instance")
    util = [load[p][a] / inst.cap[a] for (p, a) in active]

    if isempty(util)
        @objective(model, Min, 0)
        optimize!(model)
        termination_status(model) == MOI.OPTIMAL || error("lexicographic feasibility solve was not optimal: $(termination_status(model))")
        return (values=Float64[], ranks=VariableRef[], assignment=nothing,
                active_links=active, lower_bound=0.0, upper_bound=0.0)
    end

    bounds = _affine_interval.(util)
    lo = 0.0
    hi = max(0.0, maximum(last, bounds))
    M = hi == lo ? 0.0 : nextfloat(hi)
    nlinks = length(active)

    ranks = @variable(model, [1:nlinks], lower_bound=lo, upper_bound=hi,
                      base_name="lex_sorted_utilization")
    assignment = @variable(model, [1:nlinks, 1:nlinks], Bin,
                           base_name="lex_rank_assignment")
    @constraint(model, [e=1:nlinks], sum(assignment[e, k] for k in 1:nlinks) == 1)
    @constraint(model, [k=1:nlinks], sum(assignment[e, k] for e in 1:nlinks) == 1)
    @constraint(model, [k=1:nlinks-1], ranks[k] >= ranks[k + 1])
    for e in 1:nlinks, k in 1:nlinks
        @constraint(model, ranks[k] - util[e] <= M * (1 - assignment[e, k]))
        @constraint(model, util[e] - ranks[k] <= M * (1 - assignment[e, k]))
    end

    for k in 1:nlinks
        @objective(model, Min, ranks[k])
        optimize!(model)
        status = termination_status(model)
        status == MOI.OPTIMAL || error("lexicographic rank $k was not optimal: $status")
        k < nlinks && fix(ranks[k], value(ranks[k]); force=true)
    end
    return (values=value.(ranks), ranks=ranks, assignment=assignment,
            active_links=active, lower_bound=lo, upper_bound=hi)
end
