include(joinpath(@__DIR__, "official_common.jl"))

resdir = isempty(ARGS) ? joinpath(@__DIR__, "..", "results") : abspath(ARGS[1])
records = best_known_records(resdir)
out = joinpath(resdir, "best_known.csv")
write_best_known(records, out)
println("wrote $out")
