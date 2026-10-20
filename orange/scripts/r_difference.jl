using Orange
# So sánh hệ số tách r theo ECMP từng chặng (định nghĩa của đề) và theo công thức đếm đường của calculating_r.pdf
# trên mọi cặp (u,v), mọi instance của SetA, cả hai thời kỳ.  Ghi orange/results/r_difference.csv
resdir = joinpath(@__DIR__, "..", "results")
open(joinpath(resdir, "r_difference.csv"), "w") do io
    println(io, "instance,period,pairs,pairs_differ,max_abs_diff")
    for i in 1:20, p in 1:2
        name = "setA-" * lpad(i, 2, '0')
        inst = read_instance(joinpath(@__DIR__, "..", "..", "project", "setA", name))
        rE = build_r(inst, p); rP = build_r(inst, p; mode=:pathcount)
        nd = 0; mx = 0.0
        for k in keys(rE)
            a = Dict(rE[k]); b = Dict(rP[k])
            d = maximum(abs(get(a, x, 0.0) - get(b, x, 0.0)) for x in union(keys(a), keys(b)))
            d > 1e-9 && (nd += 1)
            mx = max(mx, d)
        end
        println(io, "$name,$(p-1),$(length(rE)),$nd,$mx"); flush(io)
    end
end
