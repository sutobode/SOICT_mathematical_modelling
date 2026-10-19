using Orange
outdir = joinpath(@__DIR__, "..", "results")
for name in ("setA-01", "setA-02"), b in (0, 1, 5, 20, Inf)
    prefix = joinpath(@__DIR__, "..", "..", "project", "setA", name)
    run_instance(prefix, name, 2, 600; runs=1, budget=b, tag="-B$(b)", outdir=outdir)
end
