using Orange

function readcsv_strict(file)
    isfile(file) || return Dict{String,String}[]
    lines = filter(!isempty, readlines(file))
    isempty(lines) && return Dict{String,String}[]
    head = split(lines[1], ","; keepempty=true)
    rows = Dict{String,String}[]
    for (offset, line) in enumerate(lines[2:end])
        line_no = offset + 1
        values = split(line, ","; keepempty=true)
        length(values) == length(head) || error("malformed CSV row $file:$line_no")
        push!(rows, Dict(zip(head, values)))
    end
    return rows
end

function official_rows(resdir)
    rows = Dict{String,String}[]
    for file in sort(readdir(resdir; join=true))
        base = basename(file)
        endswith(base, ".csv") || continue
        occursin(r"^setA-[0-9]{2}-(?:wp-)?P[12].*\.csv$", base) || continue
        occursin("-loads.csv", base) && continue
        for row in readcsv_strict(file)
            get(row, "routing_mode", "") == "pathcount" || continue
            get(row, "objective_mode", "") == "pure_mlu" || continue
            get(row, "experiment", "") == "official" || continue
            P = something(tryparse(Int, get(row, "P", "")), 0)
            expected_limit = P == 1 ? 1800.0 : P == 2 ? 3600.0 : NaN
            time_limit = something(tryparse(Float64, get(row, "time_limit", "")), NaN)
            time_limit == expected_limit || continue
            row["source_csv"] = base
            push!(rows, row)
        end
    end
    return rows
end

function grouped_official_rows(resdir)
    groups = Dict{Tuple{String,Int,String},Vector{Dict{String,String}}}()
    for row in official_rows(resdir)
        P = something(tryparse(Int, get(row, "P", "")), 0)
        key = (get(row, "instance", ""), P, get(row, "model_type", ""))
        push!(get!(groups, key, Dict{String,String}[]), row)
    end
    return groups
end

function verify_official_artifact(row, resdir)
    sr = joinpath(resdir, get(row, "srpaths_file", ""))
    loads = joinpath(resdir, get(row, "loads_file", ""))
    isfile(sr) && isfile(loads) || return "missing_artifact"
    script = joinpath(@__DIR__, "verify_srpaths.py")
    cmd = `python -I $script --single $(row["instance"]) $(row["P"]) $sr pathcount $(row["mlu"]) $loads $(row["run"])`
    try
        run(pipeline(cmd; stdout=devnull, stderr=devnull))
        return "verified"
    catch
        return "verification_failed"
    end
end

fmt_official(x; digits=5) = !isfinite(x) ? "N/A" : string(round(x; digits=digits))

function best_known_records(resdir; copy_artifacts=true)
    groups = grouped_official_rows(resdir)
    records = Dict{Tuple{String,Int},Dict{String,String}}()
    keys_ip = sort(unique((name, P) for (name, P, _) in keys(groups)))
    artifact_dir = joinpath(resdir, "official-artifacts")
    copy_artifacts && mkpath(artifact_dir)
    for (name, P) in keys_ip
        summaries = Tuple{String,Any}[]
        for model_type in ("full_arc", "restricted_waypoint")
            rows = get(groups, (name, P, model_type), Dict{String,String}[])
            isempty(rows) || push!(summaries, (model_type, summarize_official_rows(rows)))
        end
        complete = filter(x -> x[2].complete && x[2].best_row !== nothing, summaries)
        record = Dict("instance" => name, "P" => string(P), "routing_mode" => "pathcount")
        full_rows_all = get(groups, (name, P, "full_arc"), Dict{String,String}[])
        if isempty(full_rows_all)
            record["full_model_status"] = "not_run"
        elseif all(r -> startswith(get(r, "status", ""), "SKIPPED_"), full_rows_all)
            record["full_model_status"] = join(sort(unique(get(r, "status", "") for r in full_rows_all)), "/")
        else
            full_check = summarize_official_rows(full_rows_all)
            record["full_model_status"] = full_check.complete ? "complete" : "incomplete $(full_check.successful_runs)/10"
        end
        if isempty(complete)
            counts = isempty(summaries) ? "0" : join([string(x[2].successful_runs) for x in summaries], "/")
            record["model_type"] = "none"
            record["run_count"] = counts
            record["status"] = "INCOMPLETE"
            record["best_mlu"] = "NaN"
            record["verification_status"] = "not_verified"
            records[(name, P)] = record
            continue
        end
        model_type, summary = first(sort(complete; by=x -> (parse(Float64, x[2].best_row["mlu"]), x[1])))
        best = summary.best_row
        verification = verify_official_artifact(best, resdir)
        record["model_type"] = model_type
        record["run_count"] = string(summary.run_count)
        record["successful_runs"] = string(summary.successful_runs)
        record["optimal_runs"] = string(summary.optimal_runs)
        record["avg_solve_time"] = string(summary.avg_time)
        record["avg_gap"] = string(summary.avg_gap)
        record["avg_nodes"] = string(summary.avg_nodes)
        record["best_run"] = best["run"]
        record["source_csv"] = best["source_csv"]
        record["verification_status"] = verification
        record["original_problem_optimal"] = string(model_type == "full_arc" && get(best, "original_problem_optimal", "false") == "true")
        full_rows = full_rows_all
        full_summary = isempty(full_rows) ? nothing : summarize_official_rows(full_rows)
        original_lb = full_summary !== nothing && full_summary.complete ? full_summary.lower_bound : NaN
        record["pure_mlu_lower_bound"] = string(original_lb)
        if verification == "verified"
            record["best_mlu"] = best["mlu"]
            record["pure_mlu_gap"] = string(pure_mlu_gap(parse(Float64, best["mlu"]), original_lb))
            src_sr = joinpath(resdir, best["srpaths_file"])
            src_loads = joinpath(resdir, best["loads_file"])
            if copy_artifacts
                sr_name = "$name-P$P-pathcount-best-run$(best["run"])-srpaths.json"
                loads_name = "$name-P$P-pathcount-best-run$(best["run"])-loads.csv"
                cp(src_sr, joinpath(artifact_dir, sr_name); force=true)
                cp(src_loads, joinpath(artifact_dir, loads_name); force=true)
                record["srpaths_file"] = joinpath("official-artifacts", sr_name)
                record["loads_file"] = joinpath("official-artifacts", loads_name)
            else
                record["srpaths_file"] = best["srpaths_file"]
                record["loads_file"] = best["loads_file"]
            end
            record["status"] = model_type == "full_arc" && record["original_problem_optimal"] == "true" ?
                               "Optimal" : "Feasible upper bound (restricted)"
        else
            record["best_mlu"] = "NaN"
            record["pure_mlu_gap"] = "NaN"
            record["srpaths_file"] = ""
            record["loads_file"] = ""
            record["status"] = "UNVERIFIED"
        end
        records[(name, P)] = record
    end
    return records
end

function write_best_known(records, out)
    columns = ["instance", "P", "routing_mode", "model_type", "run_count", "successful_runs",
               "optimal_runs", "status", "best_mlu", "best_run", "source_csv", "srpaths_file",
               "loads_file", "verification_status", "original_problem_optimal", "pure_mlu_lower_bound",
               "pure_mlu_gap", "avg_solve_time", "avg_gap", "avg_nodes", "full_model_status"]
    open(out, "w") do io
        println(io, join(columns, ","))
        for key in sort(collect(keys(records)))
            row = records[key]
            println(io, join([replace(get(row, c, ""), "," => ";") for c in columns], ","))
        end
    end
    return out
end
