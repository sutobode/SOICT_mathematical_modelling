using Orange
# julia --project=orange orange/scripts/run_wp.jl <P> <tlimit> [first] [last] [max_binaries]
P = parse(Int, ARGS[1])
tlimit = parse(Float64, ARGS[2])
first_i = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 1
last_i = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 20
maxb = length(ARGS) >= 5 ? parse(Int, ARGS[5]) : 1_500_000
outdir = joinpath(@__DIR__, "..", "results")
for i in first_i:last_i
    name = "setA-" * lpad(i, 2, '0')
    prefix = joinpath(@__DIR__, "..", "..", "project", "setA", name)
    println("== $name P=$P  free RAM ", round(Sys.free_memory() / 2^30, digits=1), " GiB"); flush(stdout)
    run_wp_instance(prefix, name, P, tlimit; outdir=outdir, max_binaries=maxb)
end
