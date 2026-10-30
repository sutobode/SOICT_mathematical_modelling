# Verification of the "small budget => identical routing in all periods" reformulation.
# Standalone: uses Orange functions, does not modify the repository.
#   julia --project=orange merge_check.jl brute  <outdir>
#   julia --project=orange merge_check.jl equiv  <outdir> [seconds-per-solve]
#   julia --project=orange merge_check.jl setA05 <outdir> [seconds-per-run] [first_seed] [last_seed]
using Orange, JuMP, HiGHS, Random, Printf

const SETA = joinpath("project", "setA")
const TOY = joinpath("orange", "test", "toy", "toy")
mode, outdir = ARGS[1], ARGS[2]
mkpath(outdir)
logline(io, s) = (println(io, s); flush(io); println(s); flush(stdout))

segset(seq) = Set(zip(seq, seq[2:end]))
dist(a, b) = length(symdiff(segset(a), segset(b)))

# ---------------------------------------------------------------- step 1
function brute(io, prefix, name)
    inst = read_instance(prefix)
    n, ms = inst.n, inst.maxseg
    rng = MersenneTwister(2026)
    min_seen, pairs, viol = typemax(Int), 0, 0
    for d in eachindex(inst.dem_s)
        s, t = inst.dem_s[d], inst.dem_t[d]
        mid = [v for v in 1:n if v != s && v != t]
        seqs = Vector{Vector{Int}}([[s, t]])
        append!(seqs, [[s, w, t] for w in mid])
        append!(seqs, [[s, w1, w2, t] for w1 in mid for w2 in mid if w1 != w2])
        for a in 1:length(seqs), b in a+1:length(seqs)          # exhaustive up to 2 waypoints
            k = dist(seqs[a], seqs[b]); pairs += 1
            k < 3 && (viol += 1); min_seen = min(min_seen, k)
        end
        for _ in 1:20_000                                      # random pairs up to maxSeg segments
            mk() = [s; shuffle(rng, mid)[1:rand(rng, 0:min(ms - 1, length(mid)))]; t]
            p1, p2 = mk(), mk()
            p1 == p2 && continue
            k = dist(p1, p2); pairs += 1
            k < 3 && (viol += 1); min_seen = min(min_seen, k)
        end
    end
    logline(io, "$name,$(length(inst.dem_s)),$pairs,$min_seen,$viol")
end

# ---------------------------------------------------------------- merged model
"One routing x[d,i,j] shared by all P periods (exact when every budget(t) < 3). Loads use each period's r."
function build_merged(inst, rs, P, optimizer; tlimit, start)
    n, nD = inst.n, length(inst.dem_s)
    model = Model(optimizer)
    set_silent(model)
    set_time_limit_sec(model, tlimit)
    @variable(model, x[d=1:nD, i=1:n, j=1:n; i != j], Bin)
    @variable(model, z >= 0)
    for i in 1:n, j in 1:n
        (i == j || all(p -> haskey(rs[p], (i, j)), 1:P)) && continue
        for d in 1:nD
            fix(x[d, i, j], 0.0; force=true)               # segment must exist in every period's graph
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
    if start !== nothing
        S = Dict(d => segset(start[(d, 1)]) for d in 1:nD)
        for d in 1:nD, i in 1:n, j in 1:n
            i == j && continue
            set_start_value(x[d, i, j], (i, j) in S[d] ? 1.0 : 0.0)
        end
        set_start_value(z, max_utilization(inst, rs, start, P))
    end
    return model, x, z
end

function merged_paths(inst, x, P)
    paths = Dict{Tuple{Int,Int},Vector{Int}}()
    for d in eachindex(inst.dem_s)
        s, t = inst.dem_s[d], inst.dem_t[d]
        succ = Dict(i => j for i in 1:inst.n for j in 1:inst.n if i != j && value(x[d, i, j]) > 0.5)
        seq = [s]
        while seq[end] != t
            push!(seq, succ[seq[end]])
            length(seq) > inst.n && error("no s-t path for demand $d")
        end
        for p in 1:P
            paths[(d, p)] = seq
        end
    end
    return paths
end

opt(seed) = optimizer_with_attributes(HiGHS.Optimizer, "threads" => 1, "mip_rel_gap" => 1e-6, "random_seed" => seed)
status(m) = termination_status(m) == MOI.OPTIMAL ? "Optimal" : string(termination_status(m))
bound(m) = try objective_bound(m) catch; NaN end

"Solve original (two routings + budget) and merged (one routing) models for P=2 with an overridden budget."
function equiv(io, name, beta, tlimit)
    inst = read_instance(joinpath(SETA, name); budget=beta)
    P = 2
    rs = [build_r(inst, p; mode=:pathcount) for p in 1:P]
    start, _ = local_search(inst, rs, P; time_limit=30.0)
    same_start = all(start[(d, 1)] == start[(d, 2)] for d in eachindex(inst.dem_s))
    # original model (as in the official experiments, objective min z)
    m1, x1, z1, _ = build_model(inst, rs, P, opt(1); tlimit=tlimit, eps=0.0, start_paths=start)
    set_optimizer_attribute(m1, "presolve", Orange.presolve_setting(num_variables(m1)))
    t1 = @elapsed optimize!(m1)
    p1 = has_values(m1) ? extract_paths(inst, x1, P) : nothing
    mlu1 = p1 === nothing ? NaN : max_utilization(inst, rs, p1, P)
    ch1 = p1 === nothing ? -1 : sum(dist(p1[(d, 1)], p1[(d, 2)]) for d in eachindex(inst.dem_s))
    # merged model
    m2, x2, z2 = build_merged(inst, rs, P, opt(1); tlimit=tlimit, start=same_start ? start : nothing)
    t2 = @elapsed optimize!(m2)
    p2 = has_values(m2) ? merged_paths(inst, x2, P) : nothing
    mlu2 = p2 === nothing ? NaN : check_solution(inst, rs, p2, P, value(z2) + 1e-6).mlu
    file = joinpath(outdir, "$name-beta$beta-merged-srpaths.json")
    p2 === nothing || write_srpaths(inst, p2, P, file)
    p2 === nothing || write_loads(inst, rs, p2, P, replace(file, "srpaths.json" => "loads.csv");
                                  run_id=1, instance=name, routing_mode="pathcount")
    logline(io, @sprintf("%s,%d,%s,%.10f,%.10f,%.1f,%d,%s,%.10f,%.10f,%.1f,%d,%d,%d,%d",
        name, beta, status(m1), mlu1, bound(m1), t1, ch1, status(m2), mlu2, bound(m2), t2,
        num_variables(m1), num_variables(m2), num_constraints(m1; count_variable_in_set_constraints=false),
        num_constraints(m2; count_variable_in_set_constraints=false)))
end

function setA05(io, tlimit, seeds)
    name = "setA-05"
    inst = read_instance(joinpath(SETA, name))
    P = 2
    all(inst.budget[p] < 3 for p in 2:P) || error("merged model is exact only when every budget < 3")
    rs = [build_r(inst, p; mode=:pathcount) for p in 1:P]
    start, start_mlu = local_search(inst, rs, P; time_limit=min(30.0, 0.05 * tlimit))
    same_start = all(start[(d, 1)] == start[(d, 2)] for d in eachindex(inst.dem_s))
    logline(io, "# start_mlu=$start_mlu same_start=$same_start base_mlu=$(base_mlu(inst, rs, P))")
    for seed in seeds
        m, x, z = build_merged(inst, rs, P, opt(seed); tlimit=tlimit, start=same_start ? start : nothing)
        set_optimizer_attribute(m, "presolve", Orange.presolve_setting(num_variables(m)))
        set_optimizer_attribute(m, "log_to_console", false)
        set_optimizer_attribute(m, "log_file", joinpath(outdir, "setA-05-P2-merged-seed$seed.log"))
        unset_silent(m)
        set_optimizer_attribute(m, "log_to_console", false)
        wall = @elapsed optimize!(m)
        paths = has_values(m) ? merged_paths(inst, x, P) : nothing
        chk = paths === nothing ? nothing : check_solution(inst, rs, paths, P, value(z) + 1e-6)
        mlu = chk === nothing ? NaN : chk.mlu
        file = joinpath(outdir, "setA-05-P2-merged-seed$seed-srpaths.json")
        if paths !== nothing
            write_srpaths(inst, paths, P, file)
            write_loads(inst, rs, paths, P, replace(file, "srpaths.json" => "loads.csv");
                        run_id=seed, instance=name, routing_mode="pathcount")
        end
        logline(io, @sprintf("%d,%s,%.10f,%.10f,%.1f,%.1f,%s,%d,%s", seed, status(m), mlu, bound(m),
            solve_time(m), wall, try string(node_count(m)) catch; "NaN" end, num_variables(m),
            chk === nothing ? "none" : string(chk.budget_changes)))
    end
end

if mode == "brute"
    open(joinpath(outdir, "brute.csv"), "w") do io
        logline(io, "instance,demands,pairs_checked,min_nonzero_dist,pairs_below_3")
        brute(io, TOY, "toy")
        brute(io, joinpath(SETA, "setA-01"), "setA-01")
    end
elseif mode == "equiv"
    tl = length(ARGS) >= 3 ? parse(Float64, ARGS[3]) : 900.0
    open(joinpath(outdir, "equiv.csv"), "w") do io
        logline(io, "instance,beta,orig_status,orig_mlu,orig_bound,orig_time,orig_changes,merged_status,merged_mlu,merged_bound,merged_time,orig_vars,merged_vars,orig_cons,merged_cons")
        for name in ("setA-01", "setA-02", "setA-03"), beta in (0, 1, 2, 3)
            try
                equiv(io, name, beta, tl)
            catch e
                logline(io, "$name,$beta,ERROR,$(replace(sprint(showerror, e), "," => ";", "\n" => " "))")
            end
        end
    end
elseif mode == "setA05"
    tl = length(ARGS) >= 3 ? parse(Float64, ARGS[3]) : 3600.0
    s1 = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 1
    s2 = length(ARGS) >= 5 ? parse(Int, ARGS[5]) : 10
    open(joinpath(outdir, "setA05-merged.csv"), "a") do io
        logline(io, "seed,status,mlu,bound,highs_time,wall,nodes,vars,budget_changes")
        setA05(io, tl, s1:s2)
    end
end
