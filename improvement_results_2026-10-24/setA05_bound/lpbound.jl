# LP relaxation of the setA-05 P2 merged model (exact for budget 1) solved by a non-simplex LP method.
# Its optimum is a valid lower bound on the setA-05 P2 MLU.
#   julia --project=orange lpbound.jl <outdir> <ipm|pdlp> [seconds]
using Orange, JuMP, HiGHS, Printf

outdir, method = ARGS[1], ARGS[2]
tlimit = length(ARGS) >= 3 ? parse(Float64, ARGS[3]) : 7200.0
mkpath(outdir)
inst = read_instance(joinpath("project", "setA", "setA-05"))
P = 2
all(inst.budget[p] < 3 for p in 2:P) || error("merged model is exact only when every budget < 3")
rs = [build_r(inst, p; mode=:pathcount) for p in 1:P]
n, nD = inst.n, length(inst.dem_s)

model = Model(HiGHS.Optimizer)
set_attribute(model, "solver", method)
set_attribute(model, "threads", 1)
set_attribute(model, "time_limit", tlimit)
set_attribute(model, "log_to_console", false)
set_attribute(model, "log_file", joinpath(outdir, "lp-$method.log"))
method == "ipm" && set_attribute(model, "run_crossover", "off")
@variable(model, 0 <= x[d=1:nD, i=1:n, j=1:n; i != j] <= 1)
@variable(model, z >= 0)
for i in 1:n, j in 1:n
    (i == j || all(p -> haskey(rs[p], (i, j)), 1:P)) && continue
    for d in 1:nD
        fix(x[d, i, j], 0.0; force=true)
    end
end
for d in 1:nD, i in 1:n
    rhs = i == inst.dem_s[d] ? 1 : (i == inst.dem_t[d] ? -1 : 0)
    @constraint(model, sum(x[d, i, j] for j in 1:n if j != i) - sum(x[d, j, i] for j in 1:n if j != i) == rhs)
    @constraint(model, sum(x[d, i, j] for j in 1:n if j != i) <= 1)
    @constraint(model, sum(x[d, j, i] for j in 1:n if j != i) <= 1)
end
for d in 1:nD
    @constraint(model, sum(x[d, i, j] for i in 1:n, j in 1:n if i != j) <= inst.maxseg)
end
for p in 1:P
    load = [AffExpr(0.0) for _ in 1:inst.m]
    for ((i, j), lst) in rs[p], (a, fr) in lst, d in 1:nD
        c = fr * inst.vol[d, p]
        c == 0 && continue
        add_to_expression!(load[a], c, x[d, i, j])
    end
    for a in 1:inst.m
        a in inst.down[p] && continue
        @constraint(model, load[a] <= inst.cap[a] * z)
    end
end
@objective(model, Min, z)
wall = @elapsed optimize!(model)
st = termination_status(model)
obj = has_values(model) ? objective_value(model) : NaN
dual = try dual_objective_value(model) catch; NaN end
line = @sprintf("%s,%s,%.10f,%.10f,%.1f,%s", method, st, obj, dual, wall, string(dual_status(model)))
println(line)
open(joinpath(outdir, "lpbound.csv"), "a") do io
    println(io, line)
end
