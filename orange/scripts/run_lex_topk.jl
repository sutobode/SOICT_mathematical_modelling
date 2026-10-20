using Orange, JuMP, HiGHS
# Tối ưu từ điển CHÍNH XÁC cho K hạng đầu của vector tải (mục tiêu (5) của đề), r theo calculating_r.pdf, mô hình theo cung.
# julia --project=orange orange/scripts/run_lex_topk.jl <instance> <P> <K> [giây_mỗi_mức=600]
# Ví dụ: julia --project=orange orange/scripts/run_lex_topk.jl setA-01 1 10
# Ghi một dòng vào orange/results/lex_topk.csv và nghiệm srpaths vào orange/results/<instance>-P<P>-lex<K>-srpaths.json.
length(ARGS) >= 3 || error("usage: run_lex_topk.jl <instance> <P> <K> [seconds-per-level]")
name = ARGS[1]
P = parse(Int, ARGS[2])
K = parse(Int, ARGS[3])
tl = length(ARGS) >= 4 ? parse(Float64, ARGS[4]) : 600.0
prefix = joinpath(@__DIR__, "..", "..", "project", "setA", name)
outdir = joinpath(@__DIR__, "..", "results")

inst = read_instance(prefix)
1 <= P <= inst.P || error("P must be between 1 and $(inst.P)")
rs = [build_r(inst, p; mode=:pathcount) for p in 1:P]
opt = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.0, "mip_abs_gap" => 0.0, "threads" => 1)
model, x, z, load = build_model(inst, rs, P, opt; eps=0.0, tlimit=tl, acyclic=true)
t = @elapsed res = lex_topk!(model, load, inst, K)

verified = false
artifact = ""
if res.proven >= 1 && termination_status(model) == JuMP.MOI.OPTIMAL
    paths = extract_paths(inst, x, P)
    chk = check_solution(inst, rs, paths, P, res.theta[1] + 1e-6)
    act(p) = [a for a in 1:inst.m if !(a in inst.down[p])]
    got = sort(vcat([utilization(inst, rs, paths, p)[act(p)] for p in 1:P]...); rev=true)
    verified = chk.budget_ok && all(isapprox.(got[1:res.proven], res.theta; atol=1e-6, rtol=1e-6))
    artifact = "$(name)-P$(P)-lex$(res.proven)-srpaths.json"
    write_srpaths(inst, paths, P, joinpath(outdir, artifact))
end
println("instance=$name P=$P K_requested=$(res.requested) K_proven=$(res.proven) time=$(round(t; digits=1))s verified=$verified")
println("theta=" * join(round.(res.theta; digits=6), ","))
csv = joinpath(outdir, "lex_topk.csv")
isfile(csv) || write(csv, "instance,P,K_requested,K_proven,seconds_per_level,total_time,mlu,verified,artifact,theta\n")
open(csv, "a") do io
    println(io, join([name, P, res.requested, res.proven, tl, round(t; digits=2), isempty(res.theta) ? "NaN" : res.theta[1],
                      verified, artifact, join(round.(res.theta; digits=6), ";")], ","))
end
