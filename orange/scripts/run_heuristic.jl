using Orange
# julia --project=orange orange/scripts/run_heuristic.jl <P> <time_limit> [first] [last]
P = parse(Int, ARGS[1])
tl = parse(Float64, ARGS[2])
first_i = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 1
last_i = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 20
outdir = joinpath(@__DIR__, "..", "results")
open(joinpath(outdir, "heuristic-P$(P).csv"), "w") do io
    println(io, "instance,P,n,m,nD,mlu_base,mlu,improvement,build_time,search_time,check")
    for i in first_i:last_i
        name = "setA-" * lpad(i, 2, '0')
        print(stderr, "== $name P=$P\n")
        row = try
            inst = read_instance(joinpath(@__DIR__, "..", "..", "project", "setA", name))
            tb = @elapsed rs = [build_r(inst, p) for p in 1:P]
            base = base_mlu(inst, rs, P)
            ts = @elapsed (paths, mlu) = local_search(inst, rs, P; time_limit=tl)
            chk = check_solution(inst, rs, paths, P, mlu; tol=1e-9)
            write_srpaths(inst, paths, P, joinpath(outdir, "heuristic-$(name)-P$(P)-srpaths.json"))
            "$name,$P,$(inst.n),$(inst.m),$(length(inst.dem_s)),$base,$mlu,$(1 - mlu / base),$tb,$ts,$(chk.budget_ok ? "ok" : "budget_violation")"
        catch e
            "$name,$P,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,$(replace(sprint(showerror, e), "," => ";", "\n" => " "))"
        end
        println(io, row); flush(io)
    end
end
