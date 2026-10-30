# setA-05 P2: reroute the demand saturating arc 84->25 with the SAME path in both periods (0 budget used),
# every other demand direct. Tries every 1- and 2-waypoint path.
#   julia --project=orange fix05.jl <outdir>
using Orange, Printf

outdir = ARGS[1]
inst = read_instance(joinpath("project", "setA", "setA-05"))
P = 2
rs = [build_r(inst, p; mode=:pathcount) for p in 1:P]
paths = direct_paths(inst, P)
u1 = utilization(inst, rs, paths, 2)
top = argmax(u1)
d = only(dd for dd in eachindex(inst.dem_s) if any(a == top for (a, _) in rs[2][(inst.dem_s[dd], inst.dem_t[dd])]) && inst.vol[dd, 2] / inst.cap[top] > 0.9)
s, t = inst.dem_s[d], inst.dem_t[d]
println("demand $d $(inst.node_id[s])->$(inst.node_id[t]), base MLU $(max_utilization(inst, rs, paths, P))")
mid = [w for w in 1:inst.n if w != s && w != t]
ok(seq) = all(p -> all(seg -> haskey(rs[p], seg), zip(seq, seq[2:end])), 1:P)
best, bestseq = Inf, Int[]
for seq in Iterators.flatten(([[s, w, t] for w in mid], [[s, w1, w2, t] for w1 in mid for w2 in mid if w1 != w2]))
    ok(seq) || continue
    paths[(d, 1)] = seq; paths[(d, 2)] = seq
    v = max_utilization(inst, rs, paths, P)
    v < best - 1e-12 && (global best, bestseq = v, seq)
end
paths[(d, 1)] = bestseq; paths[(d, 2)] = bestseq
chk = check_solution(inst, rs, paths, P, best + 1e-9)
println(@sprintf("best path %s  MLU %.10f  budget_changes %s", string(inst.node_id[bestseq]), chk.mlu, string(chk.budget_changes)))
for p in 1:P
    u = utilization(inst, rs, paths, p)
    a = argmax(u)
    println(@sprintf("t=%d max util %.10f on arc %d %d->%d", p - 1, u[a], a, inst.node_id[inst.arc_from[a]], inst.node_id[inst.arc_to[a]]))
end
f = joinpath(outdir, "setA-05-P2-reroute-srpaths.json")
write_srpaths(inst, paths, P, f)
write_loads(inst, rs, paths, P, replace(f, "srpaths.json" => "loads.csv"); run_id=1, instance="setA-05", routing_mode="pathcount")
println("wrote $f")
