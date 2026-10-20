const CSV_HEADER = "instance,P,run,n,m,nD,status,z,mlu,mlu_base,improvement,bound,gap,solve_time,nodes,check,obj,start_time,start_mlu"

clean(s) = replace(string(s), "," => ";", "\n" => " ")

const PRESOLVE_OFF_VARS = 1_200_000

"Presolve của HiGHS không kiểm tra giới hạn thời gian: với mô hình rất lớn nó chạy hàng giờ vượt xa giới hạn (đã đo: setA-04, t=0,1, 1,47 triệu biến); tắt presolve thì `optimize!` trả về gần đúng hạn."
presolve_setting(nvars::Integer) = nvars > PRESOLVE_OFF_VARS ? "off" : "choose"

"Ước lượng byte cho mô hình theo cung (đo: ~3,9 GiB cho 1 triệu biến x ở P=1; thêm ~25% cho biến y của ngân sách khi P > 1)."
arc_bytes_estimate(nx::Integer, P::Integer) = 4500.0 * nx * (P > 1 ? 1.25 : 1.0)

function solve_once(inst, rs, P, tlimit, seed, acyclic, start_paths; log_path=nothing)
    opt = optimizer_with_attributes(HiGHS.Optimizer, "random_seed" => seed, "threads" => 1,
                                    "mip_rel_gap" => 1e-6)
    # log_path: ghi nguyên văn log của HiGHS (số nút, cận dưới, tiến trình) vào file, không in ra màn hình
    model, x, z = build_model(inst, rs, P, opt; tlimit=tlimit, acyclic=acyclic, start_paths=start_paths,
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

function evaluate(inst, rs, P, model, x, z)
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
    return (; status, zv, mlu, obj, bnd, gap, t, nodes, check, paths)
end

function run_instance(prefix::AbstractString, name::AbstractString, P::Int, tlimit::Real;
                      runs::Int=10, slow_runs::Int=3, fast_threshold::Real=120.0, max_vars::Int=3_000_000,
                      outdir::AbstractString="results", r_mode::Symbol=:ecmp,
                      budget=nothing, tag::AbstractString="", mem_budget_bytes=nothing,
                      first_run::Int=1, append::Bool=false, force_runs::Bool=false,
                      solver_log_dir::AbstractString="")
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
                println(io, "$name,$P,0,$(inst.n),$(inst.m),$(length(inst.dem_s)),SKIPPED_TOO_LARGE,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,nvars=$nvars,NaN,NaN,NaN")
                return
            end
            # bảo vệ bộ nhớ: bỏ qua nếu mô hình ước lượng vượt 70% RAM trống (tránh làm sập máy / bị watchdog dừng)
            budget_bytes = mem_budget_bytes === nothing ? 0.7 * Sys.free_memory() : mem_budget_bytes
            if arc_bytes_estimate(nvars, P) > budget_bytes
                println(io, "$name,$P,0,$(inst.n),$(inst.m),$(length(inst.dem_s)),SKIPPED_LOW_MEMORY,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,est_bytes=$(round(Int, arc_bytes_estimate(nvars, P))),NaN,NaN,NaN")
                return
            end
            rs = [build_r(inst, p; mode=r_mode) for p in 1:P]
            mlu_base = base_mlu(inst, rs, P)
            # nghiệm heuristic (đi thẳng hoặc 1 waypoint) làm điểm khởi tạo cho MILP; thời gian không tính vào CPU time
            start_time = @elapsed (start_paths, start_mlu) =
                inst.maxseg >= 2 ? local_search(inst, rs, P; time_limit=min(30.0, 0.05 * tlimit)) :
                (nothing, mlu_base)
        catch e
            println(io, "$name,$P,0,NaN,NaN,NaN,ERROR,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,$(clean(sprint(showerror, e))),NaN,NaN,NaN")
            return
        end
        nD = length(inst.dem_s)
        nruns, run_id = runs, first_run          # chạy các lần first_run..runs (seed = số thứ tự lần chạy)
        while run_id <= nruns
            res = (; status="ERROR", zv=NaN, mlu=NaN, obj=NaN, bnd=NaN, gap=NaN, t=NaN, nodes=NaN,
                   check="", paths=nothing)
            try
                lp = isempty(solver_log_dir) ? nothing : joinpath(solver_log_dir, "$(name)-P$(P)$(tag)-run$(run_id).log")
                model, x, z = solve_once(inst, rs, P, tlimit, run_id, false, start_paths; log_path=lp)
                res = evaluate(inst, rs, P, model, x, z)
                # ngân sách hữu hạn: "đường + chu trình" là nới lỏng; nếu vi phạm thì giải lại với MTZ
                if res.check == "budget_violation" && P >= 2
                    t1 = res.t
                    model, x, z = solve_once(inst, rs, P, tlimit, run_id, true, start_paths; log_path=lp === nothing ? nothing : replace(lp, ".log" => "-acyclic.log"))
                    res = evaluate(inst, rs, P, model, x, z)
                    res = merge(res, (; t=res.t + t1, check=res.check == "ok" ? "ok(acyclic)" : res.check * "(acyclic)"))
                end
                if res.paths !== nothing && run_id == 1
                    write_srpaths(inst, res.paths, P, joinpath(outdir, "$(name)-P$(P)$(tag)-srpaths.json"))
                    write_loads(inst, rs, res.paths, P, joinpath(outdir, "$(name)-P$(P)$(tag)-loads.csv"))
                end
            catch e
                res = merge(res, (; status="ERROR", check=clean(sprint(showerror, e))))
            end
            impr = isnan(res.mlu) ? NaN : 1.0 - res.mlu / mlu_base
            println(io, "$name,$P,$run_id,$(inst.n),$(inst.m),$nD,$(res.status),$(res.zv),$(res.mlu),$mlu_base,$impr,$(res.bnd),$(res.gap),$(res.t),$(res.nodes),$(res.check),$(res.obj),$start_time,$start_mlu")
            flush(io)
            # lần đầu giải nhanh: chạy đủ `runs` lần; nếu chậm: chỉ `slow_runs` lần
            run_id == first_run && !force_runs && !(res.t <= fast_threshold) && (nruns = min(runs, slow_runs))
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

const WP_HEADER = "instance,P,K,n,m,nD,binaries,status,mlu,mlu_base,improvement,bound,gap,solve_time,nodes,check,obj,heur_mlu,heur_time,cg_lp,cg_iters,cg_time,lns_mlu,lns_time"

"""
Chạy mô hình waypoint (≤ 1 waypoint mỗi demand) cho một instance. K (số ứng viên mỗi demand) là lớn nhất
sao cho |D|·P·(K+1) ≤ max_binaries, tối đa n-2 (mọi nút). Nghiệm heuristic dùng để khởi tạo.
"""
function run_wp_instance(prefix::AbstractString, name::AbstractString, P::Int, tlimit::Real;
                         outdir::AbstractString="results", r_mode::Symbol=:ecmp, budget=nothing,
                         tag::AbstractString="", max_binaries::Int=1_500_000, heur_time::Real=30.0,
                         use_colgen::Bool=false, K0::Int=3, cg_extra::Int=10, mem_budget_bytes=nothing,
                         use_lns::Bool=false, lns_time::Real=300.0, lns_frac::Real=0.15,
                         skip_milp::Bool=false, cg_first::Bool=false)
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
                K = min(K, Kmem)
            end
            th = @elapsed (hp, hm) = local_search(inst, rs, P; time_limit=min(heur_time, 0.05 * tlimit))
            opt = optimizer_with_attributes(HiGHS.Optimizer, "threads" => 1, "mip_rel_gap" => 1e-6)
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
                model, y, C = build_wp_model(inst, rs, P, opt; K=K, tlimit=tlimit, start_paths=hp, cands=cands)
                binaries = sum(length(C[d]) for d in 1:nD) * P
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
                                                                total_limit=Float64(lns_time))
                    lns_mlu = lm
                    if lm < mlu - 1e-12
                        paths = lpaths
                        chk = check_solution(inst, rs, paths, P, lm + 1e-5)
                        mlu = chk.mlu
                    end
                end
                check = chk.budget_ok ? "ok" : "budget_violation"
                write_srpaths(inst, paths, P, joinpath(outdir, "$(name)-wp-P$(P)$(tag)-srpaths.json"))
                write_loads(inst, rs, paths, P, joinpath(outdir, "$(name)-wp-P$(P)$(tag)-loads.csv"))
            end
            impr = 1.0 - mlu / mlu_base
            "$name,$P,$K,$(inst.n),$(inst.m),$nD,$binaries,$status,$mlu,$mlu_base,$impr,$bnd,$gap,$solve_t,$nodes,$check,$obj,$hm,$th,$cg_lp,$cg_iters,$cg_time,$lns_mlu,$lns_time_used"
        catch e
            msg = sprint(showerror, e)
            st = occursin("SKIPPED_LOW_MEMORY", msg) ? "SKIPPED_LOW_MEMORY" : "ERROR"
            "$name,$P,NaN,NaN,NaN,NaN,NaN,$st,NaN,NaN,NaN,NaN,NaN,NaN,NaN,$(clean(msg)),NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN"
        end
        println(io, row)
    end
    return csv
end
