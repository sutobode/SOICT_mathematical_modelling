# Is the setA-05 P2 MLU (0.99999) a physical limit? Routing-independent lower bounds on MLU.
#   julia --project=orange bottleneck.jl <outdir>
# Bounds (valid for every routing, waypoints or not, in period p):
#   node-out: all traffic sourced at v leaves through v's active out-arcs -> MLU >= vol_out(v) / cap_out(v)
#   node-in : all traffic sinking at v enters through v's active in-arcs  -> MLU >= vol_in(v) / cap_in(v)
#   forced  : if removing arc a disconnects s_d from t_d in G_p, all of demand d crosses a -> MLU >= sum / cap(a)
using Orange, Printf

outdir = ARGS[1]
mkpath(outdir)
inst = read_instance(joinpath("project", "setA", "setA-05"))
P = 2
rs = [build_r(inst, p; mode=:pathcount) for p in 1:P]
io = open(joinpath(outdir, "bottleneck.txt"), "w")
out(s) = (println(io, s); println(s); flush(io); flush(stdout))

active(p) = [a for a in 1:inst.m if !(a in inst.down[p])]
function reachable(p, s, banned)
    seen = falses(inst.n); seen[s] = true; stack = [s]
    while !isempty(stack)
        u = pop!(stack)
        for a in active(p)
            (a == banned || inst.arc_from[a] != u) && continue
            v = inst.arc_to[a]
            seen[v] || (seen[v] = true; push!(stack, v))
        end
    end
    return seen
end

out("instance setA-05, n=$(inst.n), arcs=$(inst.m), demands=$(length(inst.dem_s)), budget=$(inst.budget)")
for p in 1:P
    out("\n=== period t=$(p - 1)  down arcs: $(inst.down[p]) " *
        join(["($(inst.node_id[inst.arc_from[a]])->$(inst.node_id[inst.arc_to[a]]) cap=$(inst.cap[a]))" for a in inst.down[p]], " "))
    out(@sprintf("total volume %.3f", sum(inst.vol[:, p])))
    u = utilization(inst, rs, direct_paths(inst, P), p)
    order = sortperm(u; rev=true)
    out("-- baseline (direct <s,t>) top 5 arcs")
    for a in order[1:5]
        out(@sprintf("arc %d  %d->%d  cap=%.3f  util=%.6f", a, inst.node_id[inst.arc_from[a]], inst.node_id[inst.arc_to[a]], inst.cap[a], u[a]))
    end
    top = order[1]
    contrib = [(d, sum((fr * inst.vol[d, p] for (a, fr) in get(rs[p], (inst.dem_s[d], inst.dem_t[d]), []) if a == top); init=0.0))
               for d in eachindex(inst.dem_s)]
    contrib = sort(filter(c -> c[2] > 0, contrib); by=last, rev=true)
    out("-- demands on the top baseline arc $top (demand, s, t, vol, load on arc)")
    for (d, l) in contrib[1:min(8, end)]
        out(@sprintf("d=%d  %d->%d  vol=%.3f  load=%.3f", d, inst.node_id[inst.dem_s[d]], inst.node_id[inst.dem_t[d]], inst.vol[d, p], l))
    end

    best = (0.0, "none")
    for v in 1:inst.n
        co = sum((inst.cap[a] for a in active(p) if inst.arc_from[a] == v); init=0.0)
        ci = sum((inst.cap[a] for a in active(p) if inst.arc_to[a] == v); init=0.0)
        vo = sum((inst.vol[d, p] for d in eachindex(inst.dem_s) if inst.dem_s[d] == v); init=0.0)
        vi = sum((inst.vol[d, p] for d in eachindex(inst.dem_s) if inst.dem_t[d] == v); init=0.0)
        co > 0 && vo / co > best[1] && (best = (vo / co, "node-out v=$(inst.node_id[v]) vol=$vo cap=$co"))
        ci > 0 && vi / ci > best[1] && (best = (vi / ci, "node-in v=$(inst.node_id[v]) vol=$vi cap=$ci"))
    end
    out(@sprintf("-- best node-cut lower bound: %.6f  (%s)", best...))

    forced = zeros(inst.m)
    for a in active(p), d in eachindex(inst.dem_s)
        reachable(p, inst.dem_s[d], a)[inst.dem_t[d]] || (forced[a] += inst.vol[d, p])
    end
    fu = forced ./ inst.cap
    fa = argmax(fu)
    out(@sprintf("-- best forced-arc lower bound: %.6f  (arc %d %d->%d, forced vol %.3f, cap %.3f)",
        fu[fa], fa, inst.node_id[inst.arc_from[fa]], inst.node_id[inst.arc_to[fa]], forced[fa], inst.cap[fa]))
    out(@sprintf("== period t=%d routing-independent MLU lower bound: %.6f", p - 1, max(best[1], fu[fa])))
end
close(io)
