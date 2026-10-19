module Orange
using JuMP, HiGHS, Graphs, SparseArrays, JSON3, Random
include("io.jl")
include("ecmp.jl")
include("verify.jl")
include("model.jl")
include("wpmodel.jl")
include("experiment.jl")
include("heuristic.jl")
export Instance, read_instance,
       Routing, routing, ecmp_split, pathcount_split, build_r,
       changes, utilization, direct_paths, max_utilization, base_mlu,
       check_solution, write_srpaths, write_loads,
       build_model, extract_paths, lex_second_stage!,
       candidates, build_wp_model, extract_wp_paths, colgen,
       run_instance, run_wp_instance, local_search
end
