using Orange, JuMP, HiGHS

# Exact lexicographic experiment using the path-count coefficients.
# Usage:
#   julia --project=orange orange/scripts/run_lex_pathcount.jl <instance-prefix> <P> [seconds-per-rank] [srpaths-output]
# Example:
#   julia --project=orange orange/scripts/run_lex_pathcount.jl project/setA/setA-01 1 1800 orange/results/setA-01-lex-pc.json
length(ARGS) >= 2 || error("usage: run_lex_pathcount.jl <instance-prefix> <P> [seconds-per-rank] [srpaths-output]")

prefix = ARGS[1]
P = parse(Int, ARGS[2])
tlimit = length(ARGS) >= 3 ? parse(Float64, ARGS[3]) : Inf
output = length(ARGS) >= 4 ? ARGS[4] : nothing

inst = read_instance(prefix)
1 <= P <= inst.P || error("P must be between 1 and $(inst.P)")
rs = [build_r(inst, p; mode=:pathcount) for p in 1:P]
optimizer = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.0,
                                      "mip_abs_gap" => 0.0, "threads" => 1)
model, x, _, load = build_model(inst, rs, P, optimizer; eps=0.0, tlimit=tlimit, acyclic=true)
result = exact_lexicographic_loads!(model, load, inst)
termination_status(model) == JuMP.MOI.OPTIMAL ||
    error("exact lexicographic optimization did not finish optimally: $(termination_status(model))")
paths = extract_paths(inst, x, P)
check = check_lexicographic_solution(inst, rs, paths, P, x, load, result)

println("status=$(termination_status(model))")
println("active_links=$(length(result.values))")
println("sorted_utilization=" * join(result.values, ","))
println("mlu=$(check.mlu)")
println("budget_changes=" * join(["$p:$(check.budget_changes[p])" for p in sort(collect(keys(check.budget_changes)))], ","))
if output !== nothing
    temp_output = output * ".tmp"
    try
        write_srpaths(inst, paths, P, temp_output)
        exported_paths = read_srpaths(inst, temp_output, P)
        check_lexicographic_solution(inst, rs, exported_paths, P, x, load, result)
        mv(temp_output, output; force=true)
    catch
        isfile(temp_output) && rm(temp_output)
        rethrow()
    end
    println("srpaths=$output")
end
