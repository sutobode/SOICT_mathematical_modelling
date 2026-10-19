using Orange, JuMP, HiGHS
println("instance,pairs,pairs_diff,max_abs_diff,mlu0_ecmp,mlu0_pc,mlu_ecmp,mlu_pc,mlu_pc_under_ecmp")
for i in 1:4
    name = "setA-" * lpad(i, 2, '0')
    inst = read_instance(joinpath(@__DIR__, "..", "..", "project", "setA", name))
    rE = build_r(inst, 1); rP = build_r(inst, 1; mode=:pathcount)
    diffs = [maximum(abs(get(Dict(rE[k]), a, 0.0) - get(Dict(rP[k]), a, 0.0))
                     for a in union(first.(rE[k]), first.(rP[k]))) for k in keys(rE)]
    opt = optimizer_with_attributes(HiGHS.Optimizer, "threads" => 1)
    res = Dict{Symbol,Any}()
    for (tag, r) in ((:E, rE), (:P, rP))
        model, x, z = build_model(inst, [r], 1, opt; tlimit=600)
        optimize!(model)
        res[tag] = (mlu=value(z), paths=extract_paths(inst, x, 1))
    end
    # nghiệm tối ưu theo đếm đường, nhưng mạng thật chạy ECMP
    cross = max_utilization(inst, [rE], res[:P].paths, 1)
    println(join([name, length(diffs), count(>(1e-9), diffs), maximum(diffs),
                  base_mlu(inst, [rE], 1), base_mlu(inst, [rP], 1), res[:E].mlu, res[:P].mlu, cross], ","))
end
