"Số đoạn khác nhau giữa hai đường segment (dist của đề)."
function changes(a::Vector{Int}, b::Vector{Int})
    return length(symdiff(Set(zip(a, a[2:end])), Set(zip(b, b[2:end]))))
end

"Tải (luồng / dung lượng) từng cung tại thời kỳ p, tính độc lập với solver."
function utilization(inst::Instance, rs, paths, p::Int)
    load = zeros(inst.m)
    for d in eachindex(inst.dem_s)
        seq = paths[(d, p)]
        for (u, v) in zip(seq, seq[2:end])
            haskey(rs[p], (u, v)) || error("segment ($u,$v) has no route in period $p")
            for (a, fr) in rs[p][(u, v)]
                load[a] += fr * inst.vol[d, p]
            end
        end
    end
    return load ./ inst.cap
end

direct_paths(inst::Instance, P::Int) =
    Dict((d, p) => [inst.dem_s[d], inst.dem_t[d]] for d in eachindex(inst.dem_s), p in 1:P)

max_utilization(inst::Instance, rs, paths, P::Int) =
    maximum(maximum(utilization(inst, rs, paths, p)) for p in 1:P)

base_mlu(inst::Instance, rs, P::Int) = max_utilization(inst, rs, direct_paths(inst, P), P)

function check_solution(inst::Instance, rs, paths, P::Int, z::Real; tol=1e-6)
    for d in eachindex(inst.dem_s), p in 1:P
        length(paths[(d, p)]) - 1 <= inst.maxseg ||
            error("demand $d period $p exceeds maxSeg=$(inst.maxseg)")
    end
    mlu = max_utilization(inst, rs, paths, P)
    mlu <= z + tol * max(1.0, abs(z)) || error("recomputed MLU $mlu exceeds solver z=$z")
    budget_ok = true
    budget_changes = Dict{Int,Int}()
    for p in 2:P
        isfinite(inst.budget[p]) || continue
        ch = sum(changes(paths[(d, p-1)], paths[(d, p)]) for d in eachindex(inst.dem_s))
        budget_changes[p] = ch
        ch <= inst.budget[p] || (budget_ok = false)
    end
    return (mlu=mlu, budget_ok=budget_ok, budget_changes=budget_changes)
end

function write_srpaths(inst::Instance, paths, P::Int, file::AbstractString)
    entries = Dict{String,Any}[]
    for d in eachindex(inst.dem_s), p in 1:P
        seq = paths[(d, p)]
        length(seq) > 2 || continue
        push!(entries, Dict("d" => d - 1, "t" => p - 1, "w" => [inst.node_id[v] for v in seq[2:end-1]]))
    end
    open(io -> JSON3.pretty(io, Dict("srpaths" => entries)), file, "w")
end

function write_loads(inst::Instance, rs, paths, P::Int, file::AbstractString;
                     run_id=0, instance="", routing_mode="")
    base_util = [utilization(inst, rs, direct_paths(inst, P), p) for p in 1:P]
    opt_util = [utilization(inst, rs, paths, p) for p in 1:P]
    active = [(p, a) for p in 1:P for a in 1:inst.m if !(a in inst.down[p])]
    base = sort([base_util[p][a] for (p, a) in active]; rev=true)
    opt = sort([opt_util[p][a] for (p, a) in active]; rev=true)
    metadata = (run_id, instance, P, routing_mode)
    open(file, "w") do io
        println(io, "kind,rank,period,link_id,base,opt,run,instance,P,routing_mode")
        for k in eachindex(base)
            println(io, "sorted,$k,,,$(base[k]),$(opt[k]),$(metadata[1]),$(metadata[2]),$(metadata[3]),$(metadata[4])")
        end
        for (p, a) in active
            println(io, "arc,,$(p - 1),$(inst.link_id[a]),$(base_util[p][a]),$(opt_util[p][a]),$(metadata[1]),$(metadata[2]),$(metadata[3]),$(metadata[4])")
        end
    end
end

"Validate that an exact lexicographic model exports precisely the route it optimized."
function check_lexicographic_solution(inst::Instance, rs, paths, P::Int, x, load, result; tol=1e-6)
    exported_util = Float64[]
    for p in 1:P
        util = utilization(inst, rs, paths, p)
        for d in eachindex(inst.dem_s)
            path_edges = Set(zip(paths[(d, p)], paths[(d, p)][2:end]))
            model_edges = Set((i, j) for i in 1:inst.n for j in 1:inst.n if i != j &&
                              value(x[d, p, i, j]) > 0.5)
            path_edges == model_edges ||
                error("exported route differs from selected model arcs for demand $d period $p")
        end
        for a in 1:inst.m
            a in inst.down[p] && continue
            model_util = value(load[p][a]) / inst.cap[a]
            abs(util[a] - model_util) <= tol * max(1.0, abs(model_util)) ||
                error("exported utilization differs from model at period $p link $(inst.link_id[a])")
            push!(exported_util, util[a])
        end
    end
    sorted_util = sort(exported_util; rev=true)
    length(sorted_util) == length(result.values) ||
        error("exported load vector has the wrong number of entries")
    all(isapprox(a, b; atol=tol, rtol=tol) for (a, b) in zip(sorted_util, result.values)) ||
        error("exported sorted load vector differs from the lexicographic optimum")
    mlu = isempty(sorted_util) ? 0.0 : first(sorted_util)
    chk = check_solution(inst, rs, paths, P, mlu; tol=tol)
    chk.budget_ok || error("exported route violates the intervention budget")
    model_changes = Dict{Int,Int}()
    for p in 2:P
        isfinite(inst.budget[p]) || continue
        model_changes[p] = sum((value(x[d, p, i, j]) > 0.5) !=
                               (value(x[d, p-1, i, j]) > 0.5)
                               for d in eachindex(inst.dem_s)
                               for i in 1:inst.n for j in 1:inst.n if i != j)
    end
    chk.budget_changes == model_changes ||
        error("exported budget changes differ from the optimized model")
    return chk
end

"a <=_lex b (hai vector đã sắp giảm dần), so sánh có dung sai."
function lex_leq(a, b; tol=1e-7)
    for (x, y) in zip(a, b)
        x < y - tol && return true
        x > y + tol && return false
    end
    return true
end

"Đọc file srpaths (định dạng của đề) thành paths[(d,p)] = [nguồn, waypoint..., đích] theo chỉ số đỉnh."
function read_srpaths(inst::Instance, file::AbstractString, P::Int)
    v_of = Dict(id => k for (k, id) in enumerate(inst.node_id))
    wp = Dict{Tuple{Int,Int},Vector{Int}}()
    for e in JSON3.read(read(file, String)).srpaths
        wp[(Int(e.d) + 1, Int(e.t) + 1)] = Int[v_of[Int(w)] for w in e.w]
    end
    return Dict((d, p) => vcat(inst.dem_s[d], get(wp, (d, p), Int[]), inst.dem_t[d])
                for d in eachindex(inst.dem_s), p in 1:P)
end
