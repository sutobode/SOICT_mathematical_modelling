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
    mlu = max_utilization(inst, rs, paths, P)
    mlu <= z + tol * max(1.0, abs(z)) || error("recomputed MLU $mlu exceeds solver z=$z")
    budget_ok = true
    for p in 2:P
        isfinite(inst.budget[p]) || continue
        ch = sum(changes(paths[(d, p-1)], paths[(d, p)]) for d in eachindex(inst.dem_s))
        ch <= inst.budget[p] || (budget_ok = false)
    end
    return (mlu=mlu, budget_ok=budget_ok)
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

function write_loads(inst::Instance, rs, paths, P::Int, file::AbstractString)
    collect_loads(ps) = sort(vcat([utilization(inst, rs, ps, p)[[a for a in 1:inst.m if !(a in inst.down[p])]]
                                   for p in 1:P]...); rev=true)
    base = collect_loads(direct_paths(inst, P))
    opt = collect_loads(paths)
    open(file, "w") do io
        println(io, "rank,base,opt")
        for k in eachindex(base)
            println(io, "$k,$(base[k]),$(opt[k])")
        end
    end
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
