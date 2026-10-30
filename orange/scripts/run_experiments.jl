using Orange
include(joinpath(@__DIR__, "official_common.jl"))
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
maxvars = configured_max_vars()
force_raw = get(ENV, "ORANGE_FORCE_RESTART", "0")
force_raw in ("0", "1") || error("ORANGE_FORCE_RESTART must be 0 or 1")
force_restart = force_raw == "1"
outerforce = first_run > 1 || !isempty(suffix)                            # có khoảng chạy cụ thể: luôn chạy đủ các lần được giao
expected_limit = P == 1 ? 1800.0 : P == 2 ? 3600.0 : error("official experiments support only P=1 or P=2")
(tlimit == expected_limit || occursin("smoke", lowercase(suffix))) ||
    error("official P=$P experiments require tlimit=$expected_limit; shorter limits are allowed only for a -smoke run")
outdir = joinpath(@__DIR__, "..", "results")
for i in first_i:last_i, run_id in first_run:nruns
    name = "setA-" * lpad(i, 2, '0')
    prefix = joinpath(@__DIR__, "..", "..", "project", "setA", name)
    tag = "-official-pc-r$(run_id)" * suffix
    println("== $name P=$P pathcount official run=$run_id  ", time()); flush(stdout)
    action = run_official_with_resume(outdir, name, P, "full_arc", run_id, tlimit;
                                      force=force_restart) do
        run_instance(prefix, name, P, tlimit; outdir=outdir, r_mode=:pathcount, tag=tag,
                     runs=run_id, first_run=run_id, force_runs=outerforce,
                     max_vars=maxvars, mem_budget_bytes=membudget,
                     solver_log_dir=joinpath(outdir, "solverlogs"), official=true,
                     objective_mode=:pure_mlu)
    end
    println("   $action")
end
