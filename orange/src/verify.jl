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
