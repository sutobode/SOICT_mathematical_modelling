using Orange

# Official restricted-waypoint statistical runs. These are feasible upper bounds,
# never certificates of optimality for the original maxSeg problem.
# julia --project=orange orange/scripts/run_official_wp.jl <P> <tlimit> [first] [last] [first_run] [last_run] [max_binaries]
P = parse(Int, ARGS[1])
tlimit = parse(Float64, ARGS[2])
first_i = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 1
last_i = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 20
first_run = length(ARGS) >= 5 ? parse(Int, ARGS[5]) : 1
last_run = length(ARGS) >= 6 ? parse(Int, ARGS[6]) : 10
maxb = length(ARGS) >= 7 ? parse(Int, ARGS[7]) : 1_500_000
expected_limit = P == 1 ? 1800.0 : P == 2 ? 3600.0 : error("official experiments support only P=1 or P=2")
tlimit == expected_limit || error("official P=$P experiments require tlimit=$expected_limit")
1 <= first_run <= last_run <= 10 || error("official run range must be within 1:10")

outdir = joinpath(@__DIR__, "..", "results")
for i in first_i:last_i, run_id in first_run:last_run
    name = "setA-" * lpad(i, 2, '0')
    prefix = joinpath(@__DIR__, "..", "..", "project", "setA", name)
    println("== $name P=$P pathcount restricted_waypoint run=$run_id"); flush(stdout)
    run_wp_instance(prefix, name, P, tlimit; outdir=outdir, max_binaries=maxb,
                    r_mode=:pathcount, tag="-official-pc-r$(run_id)", run_id=run_id,
                    official=true, objective_mode=:pure_mlu)
end
