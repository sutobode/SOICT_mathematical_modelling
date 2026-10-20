using Orange
# Official full-arc experiments. Routing is always path-count and the objective is pure MLU.
# julia --project=orange orange/scripts/run_experiments.jl <P> <tlimit> [first] [last] [first_run] [last_run] [tag_suffix] [mem_budget_GB]
# The legacy literal `pc` is also accepted between [last] and [first_run].
P = parse(Int, ARGS[1])
tlimit = parse(Float64, ARGS[2])
first_i = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 1
last_i = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 20
length(ARGS) >= 5 && ARGS[5] == "ecmp" && error("official experiments do not accept ECMP")
legacy_pc = length(ARGS) >= 5 && ARGS[5] == "pc"
base = legacy_pc ? 6 : 5
first_run = length(ARGS) >= base ? parse(Int, ARGS[base]) : 1
nruns = length(ARGS) >= base + 1 ? parse(Int, ARGS[base + 1]) : 10
suffix = length(ARGS) >= base + 2 ? ARGS[base + 2] : ""
membudget = length(ARGS) >= base + 3 ? parse(Float64, ARGS[base + 3]) * 1e9 : nothing
outerforce = first_run > 1 || !isempty(suffix)                            # có khoảng chạy cụ thể: luôn chạy đủ các lần được giao
expected_limit = P == 1 ? 1800.0 : P == 2 ? 3600.0 : error("official experiments support only P=1 or P=2")
(tlimit == expected_limit || occursin("smoke", lowercase(suffix))) ||
    error("official P=$P experiments require tlimit=$expected_limit; shorter limits are allowed only for a -smoke run")
outdir = joinpath(@__DIR__, "..", "results")
for i in first_i:last_i
    name = "setA-" * lpad(i, 2, '0')
    prefix = joinpath(@__DIR__, "..", "..", "project", "setA", name)
    println("== $name P=$P pathcount official  ", time()); flush(stdout)
    run_instance(prefix, name, P, tlimit; outdir=outdir, r_mode=:pathcount, tag="-pc" * suffix,
                  runs=nruns, first_run=first_run, force_runs=outerforce, mem_budget_bytes=membudget,
                  solver_log_dir=joinpath(outdir, "solverlogs"), official=true,
                  objective_mode=:pure_mlu)
end
