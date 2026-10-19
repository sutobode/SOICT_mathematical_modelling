const CSV_HEADER = "instance,P,run,n,m,nD,status,z,mlu,mlu_base,improvement,bound,gap,solve_time,nodes,check,obj,start_time,start_mlu"

clean(s) = replace(string(s), "," => ";", "\n" => " ")

function solve_once(inst, rs, P, tlimit, seed, acyclic, start_paths)
    opt = optimizer_with_attributes(HiGHS.Optimizer, "random_seed" => seed, "threads" => 1,
                                    "mip_rel_gap" => 1e-6)
    model, x, z = build_model(inst, rs, P, opt; tlimit=tlimit, acyclic=acyclic, start_paths=start_paths)
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
                      budget=nothing, tag::AbstractString="")
    mkpath(outdir)
    csv = joinpath(outdir, "$(name)-P$(P)$(tag).csv")
    open(csv, "w") do io
        println(io, CSV_HEADER)
        local inst, rs, mlu_base, start_paths, start_mlu, start_time
        try
            inst = read_instance(prefix; budget=budget)
            nvars = length(inst.dem_s) * P * inst.n * (inst.n - 1)
            if nvars > max_vars
                println(io, "$name,$P,0,$(inst.n),$(inst.m),$(length(inst.dem_s)),SKIPPED_TOO_LARGE,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,nvars=$nvars,NaN,NaN,NaN")
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
        nruns, run_id = runs, 1
        while run_id <= nruns
            res = (; status="ERROR", zv=NaN, mlu=NaN, obj=NaN, bnd=NaN, gap=NaN, t=NaN, nodes=NaN,
                   check="", paths=nothing)
            try
                model, x, z = solve_once(inst, rs, P, tlimit, run_id, false, start_paths)
                res = evaluate(inst, rs, P, model, x, z)
                # ngân sách hữu hạn: "đường + chu trình" là nới lỏng; nếu vi phạm thì giải lại với MTZ
                if res.check == "budget_violation" && P >= 2
                    t1 = res.t
                    model, x, z = solve_once(inst, rs, P, tlimit, run_id, true, start_paths)
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
            run_id == 1 && !(res.t <= fast_threshold) && (nruns = min(runs, slow_runs))
            run_id += 1
        end
    end
    return csv
end

const WP_HEADER = "instance,P,K,n,m,nD,binaries,status,mlu,mlu_base,improvement,bound,gap,solve_time,nodes,check,obj,heur_mlu,heur_time,cg_lp,cg_iters,cg_time"

"""
Chạy mô hình waypoint (≤ 1 waypoint mỗi demand) cho một instance. K (số ứng viên mỗi demand) là lớn nhất
sao cho |D|·P·(K+1) ≤ max_binaries, tối đa n-2 (mọi nút). Nghiệm heuristic dùng để khởi tạo.
"""
function run_wp_instance(prefix::AbstractString, name::AbstractString, P::Int, tlimit::Real;
                         outdir::AbstractString="results", r_mode::Symbol=:ecmp, budget=nothing,
                         tag::AbstractString="", max_binaries::Int=1_500_000, heur_time::Real=30.0,
                         use_colgen::Bool=false, K0::Int=3)
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
            th = @elapsed (hp, hm) = local_search(inst, rs, P; time_limit=min(heur_time, 0.05 * tlimit))
            opt = optimizer_with_attributes(HiGHS.Optimizer, "threads" => 1, "mip_rel_gap" => 1e-6)
            cg_lp, cg_iters, cg_time = NaN, 0, 0.0
            cands = nothing
            if use_colgen                      # ứng viên do sinh cột chọn (thay cho K nút có độ vòng nhỏ nhất)
                cg_time = @elapsed (cands, cg_lp, cg_iters) = colgen(inst, rs, P; K0=K0)
                K = K0
                P > 1 && (cg_lp = NaN)         # với P > 1 ngân sách không được định giá: LP không phải cận dưới hợp lệ
            end
            model, y, C = build_wp_model(inst, rs, P, opt; K=K, tlimit=tlimit, start_paths=hp, cands=cands)
            binaries = sum(length(C[d]) for d in 1:nD) * P
            optimize!(model)
            st = termination_status(model)
            status = st == MOI.OPTIMAL ? "Optimal" : st == MOI.INFEASIBLE ? "Infeasible" : "Not Optimal"
            bnd = try objective_bound(model) catch; NaN end
            nodes = try node_count(model) catch; NaN end
            mlu = obj = gap = NaN
            check = "no_solution"
            if has_values(model)
                obj = objective_value(model)
                gap = max(0.0, 1.0 - bnd / obj)
                paths = extract_wp_paths(inst, y, C, P)
                chk = check_solution(inst, rs, paths, P, obj + 1e-5)
                mlu = chk.mlu
                check = chk.budget_ok ? "ok" : "budget_violation"
                write_srpaths(inst, paths, P, joinpath(outdir, "$(name)-wp-P$(P)$(tag)-srpaths.json"))
                write_loads(inst, rs, paths, P, joinpath(outdir, "$(name)-wp-P$(P)$(tag)-loads.csv"))
            end
            impr = 1.0 - mlu / mlu_base
            "$name,$P,$K,$(inst.n),$(inst.m),$nD,$binaries,$status,$mlu,$mlu_base,$impr,$bnd,$gap,$(solve_time(model)),$nodes,$check,$obj,$hm,$th,$cg_lp,$cg_iters,$cg_time"
        catch e
            "$name,$P,NaN,NaN,NaN,NaN,NaN,ERROR,NaN,NaN,NaN,NaN,NaN,NaN,NaN,$(clean(sprint(showerror, e))),NaN,NaN,NaN,NaN,NaN,NaN"
        end
        println(io, row)
    end
    return csv
end
