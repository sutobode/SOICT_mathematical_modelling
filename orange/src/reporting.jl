const OFFICIAL_RUN_IDS = collect(1:10)

_rowfloat(row, key) = something(tryparse(Float64, get(row, key, "")), NaN)
_rowint(row, key) = tryparse(Int, get(row, key, ""))
_finite_mean(values) = begin
    vals = filter(isfinite, Float64.(values))
    isempty(vals) ? NaN : sum(vals) / length(vals)
end

"A solver bound is a pure-MLU bound only when the solver objective was exactly min z."
function pure_mlu_bound(objective_mode, bound)
    objective_mode == "pure_mlu" && isfinite(bound) ? Float64(bound) : NaN
end

function pure_mlu_gap(mlu, bound)
    (isfinite(mlu) && isfinite(bound) && mlu >= 0 && bound >= 0) || return NaN
    mlu == 0 && return bound == 0 ? 0.0 : NaN
    bound <= mlu + 1e-7 * max(1.0, abs(mlu)) || error("pure-MLU bound $bound exceeds incumbent $mlu")
    return max(0.0, 1.0 - bound / mlu)
end

"Summarize one official configuration without silently accepting incomplete or mixed samples."
function summarize_official_rows(rows; expected_runs=OFFICIAL_RUN_IDS)
    isempty(rows) && return (complete=false, reason="no rows", run_count=0, successful_runs=0,
                             optimal_runs=0, best_row=nothing, avg_time=NaN, avg_gap=NaN,
                             avg_nodes=NaN, lower_bound=NaN)
    all(r -> get(r, "routing_mode", "") == "pathcount", rows) ||
        return (complete=false, reason="mixed or non-pathcount routing", run_count=0, successful_runs=0,
                optimal_runs=0, best_row=nothing, avg_time=NaN, avg_gap=NaN, avg_nodes=NaN, lower_bound=NaN)
    ids = [_rowint(r, "run") for r in rows]
    any(isnothing, ids) && return (complete=false, reason="invalid run id", run_count=0, successful_runs=0,
                                   optimal_runs=0, best_row=nothing, avg_time=NaN, avg_gap=NaN,
                                   avg_nodes=NaN, lower_bound=NaN)
    run_ids = Int[x for x in ids]
    length(unique(run_ids)) == length(run_ids) ||
        return (complete=false, reason="duplicate run id", run_count=length(unique(run_ids)), successful_runs=0,
                optimal_runs=0, best_row=nothing, avg_time=NaN, avg_gap=NaN, avg_nodes=NaN, lower_bound=NaN)
    sort(run_ids) == collect(expected_runs) ||
        return (complete=false, reason="requires runs 1:10", run_count=length(run_ids), successful_runs=0,
                optimal_runs=0, best_row=nothing, avg_time=NaN, avg_gap=NaN, avg_nodes=NaN, lower_bound=NaN)
    ordered = sort(rows; by=r -> something(_rowint(r, "run"), typemax(Int)))
    successful = filter(r -> startswith(get(r, "check", ""), "ok") && isfinite(_rowfloat(r, "mlu")), ordered)
    model_type = get(first(ordered), "model_type", "")
    all(r -> get(r, "model_type", "") == model_type, ordered) ||
        return (complete=false, reason="mixed model types", run_count=10, successful_runs=length(successful),
                optimal_runs=0, best_row=nothing, avg_time=NaN, avg_gap=NaN, avg_nodes=NaN, lower_bound=NaN)
    if model_type == "restricted_waypoint"
        ks = unique(get(r, "K", "") for r in ordered)
        length(ks) == 1 || return (complete=false, reason="mixed waypoint candidate limits", run_count=10,
                                   successful_runs=length(successful), optimal_runs=0, best_row=nothing,
                                   avg_time=NaN, avg_gap=NaN, avg_nodes=NaN, lower_bound=NaN)
    end
    length(successful) == length(expected_runs) ||
        return (complete=false, reason="fewer than 10 valid runs", run_count=length(ordered),
                successful_runs=length(successful), optimal_runs=count(r -> get(r, "status", "") == "Optimal", successful),
                best_row=nothing, avg_time=NaN, avg_gap=NaN, avg_nodes=NaN, lower_bound=NaN)
    best = first(sort(successful; by=r -> (_rowfloat(r, "mlu"), something(_rowint(r, "run"), typemax(Int)))))
    has_artifact = !isempty(get(best, "srpaths_file", "")) && !isempty(get(best, "loads_file", ""))
    has_artifact || return (complete=false, reason="best run has no artifact", run_count=10, successful_runs=10,
                            optimal_runs=count(r -> get(r, "status", "") == "Optimal", successful),
                            best_row=nothing, avg_time=NaN, avg_gap=NaN, avg_nodes=NaN, lower_bound=NaN)
    times = [_rowfloat(r, "solve_time") for r in successful]
    nodes = [_rowfloat(r, "nodes") for r in successful]
    gaps = [_rowfloat(r, "pure_mlu_gap") for r in successful]
    bounds = [_rowfloat(r, "pure_mlu_bound") for r in successful]
    avg_time = all(isfinite, times) ? _finite_mean(times) : NaN
    avg_nodes = all(isfinite, nodes) ? _finite_mean(nodes) : NaN
    avg_gap = any(isfinite, gaps) ? _finite_mean(gaps) : NaN
    original_bounds = model_type == "full_arc" ? filter(isfinite, bounds) : Float64[]
    return (complete=true, reason="", run_count=10, successful_runs=10,
            optimal_runs=count(r -> get(r, "status", "") == "Optimal", successful),
            best_row=best, avg_time=avg_time, avg_gap=avg_gap, avg_nodes=avg_nodes,
            lower_bound=isempty(original_bounds) ? NaN : maximum(original_bounds))
end
