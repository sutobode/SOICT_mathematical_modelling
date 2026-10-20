const CSV_HEADER = join(OFFICIAL_FULL_SCHEMA, ",")
const DEFAULT_MAX_VARS = 3_000_000

function configured_max_vars(env=ENV)
    raw = get(env, "ORANGE_MAX_VARS", string(DEFAULT_MAX_VARS))
    value = tryparse(Int, raw)
    value === nothing && error("ORANGE_MAX_VARS must be a positive integer")
    value > 0 || error("ORANGE_MAX_VARS must be a positive integer")
    return value
end

clean(s) = replace(string(s), "," => ";", "\n" => " ")

const PRESOLVE_OFF_VARS = 1_200_000

"Presolve của HiGHS không kiểm tra giới hạn thời gian: với mô hình rất lớn nó chạy hàng giờ vượt xa giới hạn (đã đo: setA-04, t=0,1, 1,47 triệu biến); tắt presolve thì `optimize!` trả về gần đúng hạn."
presolve_setting(nvars::Integer) = nvars > PRESOLVE_OFF_VARS ? "off" : "choose"

"Ước lượng byte cho mô hình theo cung (đo: ~3,9 GiB cho 1 triệu biến x ở P=1; thêm ~25% cho biến y của ngân sách khi P > 1)."
arc_bytes_estimate(nx::Integer, P::Integer) = 4500.0 * nx * (P > 1 ? 1.25 : 1.0)

function solve_once(inst, rs, P, tlimit, seed, acyclic, start_paths; log_path=nothing,
                    objective_mode::Symbol=:weighted_secondary)
    opt = optimizer_with_attributes(HiGHS.Optimizer, "random_seed" => seed, "threads" => 1,
                                    "mip_rel_gap" => 1e-6)
    # log_path: ghi nguyên văn log của HiGHS (số nút, cận dưới, tiến trình) vào file, không in ra màn hình
    eps = objective_mode === :pure_mlu ? 0.0 : nothing
    model, x, z = build_model(inst, rs, P, opt; tlimit=tlimit, eps=eps, acyclic=acyclic, start_paths=start_paths,
                              silent=log_path === nothing)
    if log_path !== nothing
        mkpath(dirname(log_path))
        set_optimizer_attribute(model, "log_to_console", false)
        set_optimizer_attribute(model, "log_file", log_path)
    end
    set_optimizer_attribute(model, "presolve", presolve_setting(num_variables(model)))
    optimize!(model)
    return model, x, z
end

function evaluate(inst, rs, P, model, x, z; objective_mode::Symbol=:weighted_secondary)
    st = termination_status(model)
    status = st == MOI.OPTIMAL ? "Optimal" : st == MOI.INFEASIBLE ? "Infeasible" : "Not Optimal"
    bnd = try objective_bound(model) catch; NaN end
    nodes = try node_count(model) catch; NaN end
    t = solve_time(model)
    zv = mlu = obj = gap = NaN
    paths = nothing
    check = "no_solution"
    if has_values(model)
        zv, obj = value(z), objective_value(model)
        gap = max(0.0, 1.0 - bnd / obj)                  # gap thật, kể cả khi Optimal
        paths = extract_paths(inst, x, P)
        chk = check_solution(inst, rs, paths, P, zv; tol=1e-5)
        mlu = chk.mlu
        check = chk.budget_ok ? "ok" : "budget_violation"
    end
    pure_bound = pure_mlu_bound(string(objective_mode), bnd)
    pure_gap = pure_mlu_gap(mlu, pure_bound)
    status == "Optimal" && isfinite(pure_bound) && isfinite(mlu) && (pure_gap = 0.0)
    return (; status, zv, mlu, obj, bnd, gap, pure_bound, pure_gap, t, nodes, check, paths)
end

_sum_attempt_metric(values...) = all(isfinite, values) ? sum(values) : NaN

function _fallback_result(inst, rs, P, first, start_paths, start_mlu, total_time, total_nodes;
                          objective_mode::Symbol)
    paths = start_paths === nothing ? direct_paths(inst, P) : start_paths
    chk = check_solution(inst, rs, paths, P, start_mlu + 1e-5)
    bound = first.pure_bound
    pgap = pure_mlu_gap(chk.mlu, bound)
    gap = isfinite(first.bnd) && chk.mlu > 0 ? max(0.0, 1.0 - first.bnd / chk.mlu) : NaN
    check = chk.budget_ok ? "ok(fallback)" : "budget_violation(fallback)"
    return merge(first, (; status="Not Optimal", zv=chk.mlu, mlu=chk.mlu, obj=chk.mlu,
                         gap, pure_bound=bound, pure_gap=pgap, t=total_time, nodes=total_nodes,
                         check, paths))
end

function _solve_with_acyclic_retry(inst, rs, P, total_limit, seed, start_paths, start_mlu;
                                   log_path=nothing, objective_mode::Symbol=:weighted_secondary,
                                   solve_attempt=solve_once, evaluate_attempt=evaluate)
    model, x, z = solve_attempt(inst, rs, P, total_limit, seed, false, start_paths;
                                log_path=log_path, objective_mode=objective_mode)
    first = evaluate_attempt(inst, rs, P, model, x, z; objective_mode=objective_mode)
    first.check == "budget_violation" && P >= 2 || return first

    remaining = total_limit - first.t
    remaining > 0 || return _fallback_result(inst, rs, P, first, start_paths, start_mlu,
                                              first.t, first.nodes; objective_mode=objective_mode)
    retry_log = log_path === nothing ? nothing : replace(log_path, ".log" => "-acyclic.log")
    model, x, z = solve_attempt(inst, rs, P, remaining, seed, true, start_paths;
                                log_path=retry_log, objective_mode=objective_mode)
    second = evaluate_attempt(inst, rs, P, model, x, z; objective_mode=objective_mode)
    total_time = _sum_attempt_metric(first.t, second.t)
    total_nodes = _sum_attempt_metric(first.nodes, second.nodes)
    if startswith(second.check, "ok")
        return merge(second, (; t=total_time, nodes=total_nodes, check=second.check * "(acyclic)"))
    end
    return _fallback_result(inst, rs, P, first, start_paths, start_mlu, total_time, total_nodes;
                            objective_mode=objective_mode)
end

function _write_artifacts_atomic(inst, rs, paths, P, outdir, srpaths_file, loads_file;
                                 run_id, instance, routing_mode)
    sr_final, loads_final = joinpath(outdir, srpaths_file), joinpath(outdir, loads_file)
    sr_tmp, loads_tmp = tempname(outdir), tempname(outdir)
    try
        write_srpaths(inst, paths, P, sr_tmp)
        write_loads(inst, rs, paths, P, loads_tmp;
                    run_id=run_id, instance=instance, routing_mode=routing_mode)
        mv(sr_tmp, sr_final; force=true)
        mv(loads_tmp, loads_final; force=true)
    finally
        isfile(sr_tmp) && rm(sr_tmp)
        isfile(loads_tmp) && rm(loads_tmp)
    end
end

function run_instance(prefix::AbstractString, name::AbstractString, P::Int, tlimit::Real;
                      runs::Int=10, slow_runs::Int=3, fast_threshold::Real=120.0,
                      max_vars::Int=DEFAULT_MAX_VARS,
                      outdir::AbstractString="results", r_mode::Symbol=:ecmp,
                      budget=nothing, tag::AbstractString="", mem_budget_bytes=nothing,
                       first_run::Int=1, append::Bool=false, force_runs::Bool=false,
                       solver_log_dir::AbstractString="", official::Bool=false,
                       objective_mode::Symbol=official ? :pure_mlu : :weighted_secondary)
    official && r_mode !== :pathcount && error("official experiments require r_mode=:pathcount")
    official && objective_mode !== :pure_mlu && error("official experiments require objective_mode=:pure_mlu")
    official && !(1 <= first_run <= runs <= 10) && error("official run shards must be within run IDs 1:10")
    mkpath(outdir)
    csv = joinpath(outdir, "$(name)-P$(P)$(tag).csv")
    has_header = append && isfile(csv) && filesize(csv) > 0
    open(csv, append ? "a" : "w") do io
        has_header || println(io, CSV_HEADER)
        local inst, rs, mlu_base, start_paths, start_mlu, start_time
        try
            inst = read_instance(prefix; budget=budget)
            nvars = length(inst.dem_s) * P * inst.n * (inst.n - 1)
            if nvars > max_vars
                println(io, join([name, P, 0, inst.n, inst.m, length(inst.dem_s), "SKIPPED_TOO_LARGE",
                                  NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, "nvars=$nvars", NaN, NaN, NaN,
                                  string(r_mode), "full_arc", string(objective_mode), false, NaN, NaN, "", "", "not_verified",
                                  official ? "official" : "research", tlimit, OFFICIAL_SCHEMA_VERSION], ","))
                return
            end
            # bảo vệ bộ nhớ: bỏ qua nếu mô hình ước lượng vượt 70% RAM trống (tránh làm sập máy / bị watchdog dừng)
            budget_bytes = mem_budget_bytes === nothing ? 0.7 * Sys.free_memory() : mem_budget_bytes
            if arc_bytes_estimate(nvars, P) > budget_bytes
                println(io, join([name, P, 0, inst.n, inst.m, length(inst.dem_s), "SKIPPED_LOW_MEMORY",
                                  NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,
                                  "est_bytes=$(round(Int, arc_bytes_estimate(nvars, P)))", NaN, NaN, NaN,
                                  string(r_mode), "full_arc", string(objective_mode), false, NaN, NaN, "", "", "not_verified",
                                  official ? "official" : "research", tlimit, OFFICIAL_SCHEMA_VERSION], ","))
                return
            end
            rs = [build_r(inst, p; mode=r_mode) for p in 1:P]
            mlu_base = base_mlu(inst, rs, P)
            # nghiệm heuristic (đi thẳng hoặc 1 waypoint) làm điểm khởi tạo cho MILP; thời gian không tính vào CPU time
            start_time = @elapsed (start_paths, start_mlu) =
                inst.maxseg >= 2 ? local_search(inst, rs, P; time_limit=min(30.0, 0.05 * tlimit)) :
                (nothing, mlu_base)
        catch e
            println(io, join([name, P, 0, NaN, NaN, NaN, "ERROR", NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,
                              clean(sprint(showerror, e)), NaN, NaN, NaN, string(r_mode), "full_arc",
                              string(objective_mode), false, NaN, NaN, "", "", "not_verified",
                              official ? "official" : "research", tlimit, OFFICIAL_SCHEMA_VERSION], ","))
            return
        end
        nD = length(inst.dem_s)
        nruns, run_id = runs, first_run          # chạy các lần first_run..runs (seed = số thứ tự lần chạy)
        while run_id <= nruns
            res = (; status="ERROR", zv=NaN, mlu=NaN, obj=NaN, bnd=NaN, gap=NaN, pure_bound=NaN, pure_gap=NaN, t=NaN, nodes=NaN,
                   check="", paths=nothing)
            srpaths_file = loads_file = ""
            try
                lp = isempty(solver_log_dir) ? nothing : joinpath(solver_log_dir, "$(name)-P$(P)$(tag)-run$(run_id).log")
                res = _solve_with_acyclic_retry(inst, rs, P, tlimit, run_id, start_paths, start_mlu;
                                                 log_path=lp, objective_mode=objective_mode)
                if res.paths !== nothing && startswith(res.check, "ok") && (official || run_id == 1)
                    artifact_stem = official ? "$(name)-P$(P)$(tag)-run$(run_id)" : "$(name)-P$(P)$(tag)"
                    srpaths_file = artifact_stem * "-srpaths.json"
                    loads_file = artifact_stem * "-loads.csv"
                    _write_artifacts_atomic(inst, rs, res.paths, P, outdir, srpaths_file, loads_file;
                                            run_id=run_id, instance=name, routing_mode=string(r_mode))
                end
            catch e
                res = merge(res, (; status="ERROR", check=clean(sprint(showerror, e))))
            end
            impr = isnan(res.mlu) ? NaN : 1.0 - res.mlu / mlu_base
            original_optimal = res.status == "Optimal" && objective_mode === :pure_mlu
            experiment = official ? "official" : "research"
            println(io, "$name,$P,$run_id,$(inst.n),$(inst.m),$nD,$(res.status),$(res.zv),$(res.mlu),$mlu_base,$impr,$(res.bnd),$(res.gap),$(res.t),$(res.nodes),$(res.check),$(res.obj),$start_time,$start_mlu,$(string(r_mode)),full_arc,$(string(objective_mode)),$original_optimal,$(res.pure_bound),$(res.pure_gap),$srpaths_file,$loads_file,pending,$experiment,$tlimit,$OFFICIAL_SCHEMA_VERSION")
            flush(io)
            # lần đầu giải nhanh: chạy đủ `runs` lần; nếu chậm: chỉ `slow_runs` lần
            run_id == first_run && !official && !force_runs && !(res.t <= fast_threshold) && (nruns = min(runs, slow_runs))
            run_id += 1
        end
    end
    return csv
end

"Ước lượng byte cho mỗi biến nhị phân của mô hình waypoint (2 đoạn/đường, mỗi hạng tử ~100 B, cộng ~800 B cố định)."
wp_bytes_per_binary(avg_len) = 2 * avg_len * 100 + 800

"K lớn nhất (≤ nmax) sao cho mô hình vừa `budget_bytes` RAM; `nothing` nếu ngay cả K = 0 cũng không vừa."
function choose_K(nD::Int, P::Int, nmax::Int, avg_len::Real, budget_bytes::Real)
    maxbin = floor(Int, budget_bytes / wp_bytes_per_binary(avg_len))
    K = maxbin ÷ (nD * P) - 1
    return K < 0 ? nothing : min(K, nmax)
end

const WP_HEADER = join(OFFICIAL_WP_SCHEMA, ",")

function official_wp_configuration(prefix::AbstractString, P::Int, max_binaries::Int=1_500_000)
    inst = read_instance(prefix)
    nD = length(inst.dem_s)
    K = inst.maxseg >= 2 ? clamp(max_binaries ÷ (nD * P) - 1, 0, inst.n - 2) : 0
    rs = [build_r(inst, p; mode=:pathcount) for p in 1:P]
    W = waypoint_options(inst, rs, K; extend_start_candidates=false)
    return (K=K, candidate_fingerprint=candidate_fingerprint(W))
end

"""
Chạy mô hình waypoint (≤ 1 waypoint mỗi demand) cho một instance. K (số ứng viên mỗi demand) là lớn nhất
sao cho |D|·P·(K+1) ≤ max_binaries, tối đa n-2 (mọi nút). Nghiệm heuristic dùng để khởi tạo.
"""
function run_wp_instance(prefix::AbstractString, name::AbstractString, P::Int, tlimit::Real;
                         outdir::AbstractString="results", r_mode::Symbol=:ecmp, budget=nothing,
                         tag::AbstractString="", max_binaries::Int=1_500_000, heur_time::Real=30.0,
                         use_colgen::Bool=false, K0::Int=3, cg_extra::Int=10, mem_budget_bytes=nothing,
                         use_lns::Bool=false, lns_time::Real=300.0, lns_frac::Real=0.15,
                         skip_milp::Bool=false, cg_first::Bool=false, run_id::Int=1,
                         official::Bool=false, objective_mode::Symbol=official ? :pure_mlu : :weighted_secondary)
    official && r_mode !== :pathcount && error("official experiments require r_mode=:pathcount")
    official && objective_mode !== :pure_mlu && error("official experiments require objective_mode=:pure_mlu")
    official && !(run_id in OFFICIAL_RUN_IDS) && error("official run_id must be in 1:10")
    mkpath(outdir)
    csv = joinpath(outdir, "$(name)-wp-P$(P)$(tag).csv")
    open(csv, "w") do io
        println(io, WP_HEADER)
        row = try
            inst = read_instance(prefix; budget=budget)
            nD = length(inst.dem_s)
            K = inst.maxseg >= 2 ? clamp(max_binaries ÷ (nD * P) - 1, 0, inst.n - 2) : 0
            rs = [build_r(inst, p; mode=r_mode) for p in 1:P]
            mlu_base = base_mlu(inst, rs, P)
            # bảo vệ bộ nhớ: giảm K cho vừa 50% RAM trống (hoặc ngân sách được chỉ định); không vừa thì bỏ qua
            avg_len = sum(length(v) for v in values(rs[1])) / max(1, length(rs[1]))
            budget_bytes = mem_budget_bytes === nothing ? 0.5 * Sys.free_memory() : mem_budget_bytes
            Kmem = choose_K(nD, P, inst.n - 2, avg_len, budget_bytes)
            if !use_colgen
                Kmem === nothing && error("SKIPPED_LOW_MEMORY")
                if official
                    Kmem >= K || error("SKIPPED_LOW_MEMORY")
                else
                    K = min(K, Kmem)
                end
            end
            candidate_seed = official ? 1 : run_id
            th = @elapsed (hp, hm) = local_search(inst, rs, P; time_limit=min(heur_time, 0.05 * tlimit), seed=candidate_seed)
            opt = optimizer_with_attributes(HiGHS.Optimizer, "threads" => 1, "mip_rel_gap" => 1e-6,
                                            "random_seed" => run_id)
            cg_lp, cg_iters, cg_time = NaN, 0, 0.0
            cands = nothing
            if use_colgen                      # ứng viên do sinh cột chọn (thay cho K nút có độ vòng nhỏ nhất)
                if cg_first && P > 1           # nhanh: sinh cột chỉ trên thời kỳ đầu, rồi lọc theo mọi thời kỳ
                    cg_time = @elapsed (c1, _, cg_iters) = colgen(inst, rs[1:1], 1; K0=K0, extra=cg_extra)
                    cands = filter_cands(inst, rs, c1)
                else
                    cg_time = @elapsed (cands, cg_lp, cg_iters) = colgen(inst, rs, P; K0=K0, extra=cg_extra)
                end
                K = K0
                P > 1 && (cg_lp = NaN)         # với P > 1 ngân sách không được định giá: LP không phải cận dưới hợp lệ
            end
            configured_options = waypoint_options(inst, rs, K; cands=cands, start_paths=hp,
                                                   extend_start_candidates=!official)
            candidate_hash = candidate_fingerprint(configured_options)
            status, bnd, nodes, solve_t, binaries = "Not Optimal", NaN, NaN, 0.0, 0
            mlu = obj = gap = NaN
            lns_mlu, lns_time_used = NaN, NaN
            check = "no_solution"
            paths, chk = nothing, nothing
            if skip_milp                       # bỏ MILP (kẹt ở gốc B&B với instance lớn có ngân sách): dùng heuristic + LNS
                binaries = cands === nothing ? 0 : sum(length.(cands)) * P
                paths, obj = hp, hm
                chk = check_solution(inst, rs, paths, P, hm + 1e-5)
                mlu = chk.mlu
            else
                model, y, C = build_wp_model(inst, rs, P, opt; K=K, tlimit=tlimit, start_paths=hp, cands=cands,
                                              eps=objective_mode === :pure_mlu ? 0.0 : nothing,
                                              extend_start_candidates=!official)
                binaries = sum(length(C[d]) for d in 1:nD) * P
                candidate_fingerprint(C) == candidate_hash || error("candidate set changed during model construction")
                optimize!(model)
                st = termination_status(model)
                status = st == MOI.OPTIMAL ? "Optimal" : st == MOI.INFEASIBLE ? "Infeasible" : "Not Optimal"
                bnd = try objective_bound(model) catch; NaN end
                nodes = try node_count(model) catch; NaN end
                solve_t = solve_time(model)
                if has_values(model)
                    obj = objective_value(model)
                    gap = max(0.0, 1.0 - bnd / obj)
                    paths = extract_wp_paths(inst, y, C, P)
                    chk = check_solution(inst, rs, paths, P, obj + 1e-5)
                    mlu = chk.mlu
                end
            end
            if paths !== nothing
                if use_lns                      # tinh chỉnh bằng LNS từ nghiệm hiện có; giữ nghiệm tốt hơn
                    lns_time_used = @elapsed (lpaths, lm) = lns(inst, rs, P, opt; K=K, cands=cands, start_paths=paths,
                                                                iters=10_000, frac=Float64(lns_frac), tlimit_iter=20.0,
                                                                total_limit=Float64(lns_time), seed=run_id)
                    lns_mlu = lm
                    if lm < mlu - 1e-12
                        paths = lpaths
                        chk = check_solution(inst, rs, paths, P, lm + 1e-5)
                        mlu = chk.mlu
                    end
                end
                check = chk.budget_ok ? "ok" : "budget_violation"
                artifact_stem = official ? "$(name)-wp-P$(P)$(tag)-run$(run_id)" : "$(name)-wp-P$(P)$(tag)"
                srpaths_file = artifact_stem * "-srpaths.json"
                loads_file = artifact_stem * "-loads.csv"
                _write_artifacts_atomic(inst, rs, paths, P, outdir, srpaths_file, loads_file;
                                        run_id=run_id, instance=name, routing_mode=string(r_mode))
            else
                srpaths_file = loads_file = ""
            end
            impr = 1.0 - mlu / mlu_base
            experiment = official ? "official" : "research"
            "$name,$P,$K,$(inst.n),$(inst.m),$nD,$binaries,$status,$mlu,$mlu_base,$impr,$bnd,$gap,$solve_t,$nodes,$check,$obj,$hm,$th,$cg_lp,$cg_iters,$cg_time,$lns_mlu,$lns_time_used,$run_id,$(string(r_mode)),restricted_waypoint,$(string(objective_mode)),false,NaN,NaN,$srpaths_file,$loads_file,pending,$experiment,$tlimit,$candidate_hash,$OFFICIAL_SCHEMA_VERSION"
        catch e
            msg = sprint(showerror, e)
            st = occursin("SKIPPED_LOW_MEMORY", msg) ? "SKIPPED_LOW_MEMORY" : "ERROR"
            "$name,$P,NaN,NaN,NaN,NaN,NaN,$st,NaN,NaN,NaN,NaN,NaN,NaN,NaN,$(clean(msg)),NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,$run_id,$(string(r_mode)),restricted_waypoint,$(string(objective_mode)),false,NaN,NaN,,,not_verified,$(official ? "official" : "research"),$tlimit,,$OFFICIAL_SCHEMA_VERSION"
        end
        println(io, row)
    end
    return csv
end
