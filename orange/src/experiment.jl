const CSV_HEADER = "instance,P,run,n,m,nD,status,z,mlu,mlu_base,improvement,bound,gap,solve_time,nodes,check"

clean(s) = replace(string(s), "," => ";", "\n" => " ")

function run_instance(prefix::AbstractString, name::AbstractString, P::Int, tlimit::Real;
                      runs::Int=10, fast_threshold::Real=120.0, max_vars::Int=3_000_000,
                      outdir::AbstractString="results", r_mode::Symbol=:ecmp,
                      budget=nothing, tag::AbstractString="")
    mkpath(outdir)
    csv = joinpath(outdir, "$(name)-P$(P)$(tag).csv")
    open(csv, "w") do io
        println(io, CSV_HEADER)
        local inst, rs, mlu_base
        try
            inst = read_instance(prefix; budget=budget)
            nvars = length(inst.dem_s) * P * inst.n * (inst.n - 1)
            if nvars > max_vars
                println(io, "$name,$P,0,$(inst.n),$(inst.m),$(length(inst.dem_s)),SKIPPED_TOO_LARGE,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,nvars=$nvars")
                return
            end
            rs = [build_r(inst, p; mode=r_mode) for p in 1:P]
            mlu_base = base_mlu(inst, rs, P)
        catch e
            println(io, "$name,$P,0,NaN,NaN,NaN,ERROR,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,$(clean(sprint(showerror, e)))")
            return
        end
        nD = length(inst.dem_s)
        nruns, run_id = runs, 1
        while run_id <= nruns
            status, zv, mlu, bnd, gap, t, nodes, check = "ERROR", NaN, NaN, NaN, NaN, NaN, NaN, ""
            try
                opt = optimizer_with_attributes(HiGHS.Optimizer, "random_seed" => run_id, "threads" => 1)
                model, x, z = build_model(inst, rs, P, opt; tlimit=tlimit)
                optimize!(model)
                st = termination_status(model)
                status = st == MOI.OPTIMAL ? "Optimal" : st == MOI.INFEASIBLE ? "Infeasible" : "Not Optimal"
                t = solve_time(model)
                nodes = try node_count(model) catch; NaN end
                bnd = try objective_bound(model) catch; NaN end
                if has_values(model)
                    zv = value(z)
                    paths = extract_paths(inst, x, P)
                    chk = check_solution(inst, rs, paths, P, zv; tol=1e-5)
                    mlu = chk.mlu
                    check = chk.budget_ok ? "ok" : "budget_violation"
                    gap = status == "Optimal" ? 0.0 : 1.0 - bnd / objective_value(model)
                    if run_id == 1
                        write_srpaths(inst, paths, P, joinpath(outdir, "$(name)-P$(P)$(tag)-srpaths.json"))
                        write_loads(inst, rs, paths, P, joinpath(outdir, "$(name)-P$(P)$(tag)-loads.csv"))
                    end
                else
                    check = "no_solution"
                end
            catch e
                status, check = "ERROR", clean(sprint(showerror, e))
            end
            impr = isnan(mlu) ? NaN : 1.0 - mlu / mlu_base
            println(io, "$name,$P,$run_id,$(inst.n),$(inst.m),$nD,$status,$zv,$mlu,$mlu_base,$impr,$bnd,$gap,$t,$nodes,$check")
            flush(io)
            # chỉ chạy đủ số lần nếu lần đầu giải nhanh
            run_id == 1 && !(t <= fast_threshold) && (nruns = 1)
            run_id += 1
        end
    end
    return csv
end
