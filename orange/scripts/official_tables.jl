include(joinpath(@__DIR__, "official_common.jl"))

resdir = isempty(ARGS) ? joinpath(@__DIR__, "..", "results") : abspath(ARGS[1])
reportdir = length(ARGS) >= 2 ? abspath(ARGS[2]) : (isempty(ARGS) ? joinpath(@__DIR__, "..", "..", "report") : joinpath(resdir, "report"))
records = best_known_records(resdir)

for P in (1, 2)
    rows = Vector{Vector{String}}()
    for i in 1:20
        name = "setA-" * lpad(i, 2, '0')
        record = get(records, (name, P), Dict{String,String}(
            "instance" => name, "P" => string(P), "routing_mode" => "pathcount",
            "model_type" => "none", "status" => "INCOMPLETE", "run_count" => "0",
            "best_mlu" => "NaN", "verification_status" => "not_verified"))
        source = get(record, "source_csv", "")
        source_rows = isempty(source) ? Dict{String,String}[] : readcsv_strict(joinpath(resdir, source))
        first_row = isempty(source_rows) ? Dict{String,String}() : first(source_rows)
        push!(rows, [name, get(first_row, "n", "N/A"), get(first_row, "m", "N/A"), get(first_row, "nD", "N/A"),
                     "pathcount", get(record, "model_type", "none"), get(record, "run_count", "0"),
                     get(record, "successful_runs", "0"),
                     get(record, "full_model_status", "not_run"),
                     fmt_official(something(tryparse(Float64, get(record, "best_mlu", "")), NaN)),
                     fmt_official(something(tryparse(Float64, get(record, "pure_mlu_lower_bound", "")), NaN)),
                     fmt_official(something(tryparse(Float64, get(record, "avg_solve_time", "")), NaN); digits=1),
                     fmt_official(something(tryparse(Float64, get(record, "avg_gap", "")), NaN)),
                     fmt_official(something(tryparse(Float64, get(record, "avg_nodes", "")), NaN); digits=1),
                     get(record, "optimal_runs", "0") * "/10", get(record, "status", "INCOMPLETE"),
                     get(record, "best_run", "N/A"), get(record, "verification_status", "not_verified"),
                     get(record, "srpaths_file", "")])
    end
    header = ["Instance", "Vertices", "Links", "Demands", "Routing mode", "Model type", "Run count", "Successful runs", "Full model status",
              "Best MLU", "Valid MLU lower bound", "Average solve time (s)", "Average gap",
              "Average B&B nodes", "Optimal runs", "Status", "Best run", "Verification", "Artifact"]
    csv = joinpath(resdir, "table_official_P$P.csv")
    open(csv, "w") do io
        println(io, join(header, ","))
        for row in rows
            println(io, join(replace.(row, "," => ";"), ","))
        end
    end
    md = joinpath(resdir, "table_official_P$P.md")
    open(md, "w") do io
        println(io, "# Official path-count results, P=$P\n")
        println(io, "| ", join(header, " | "), " |")
        println(io, "|", join(fill("---", length(header)), "|"), "|")
        for row in rows
            println(io, "| ", join(row, " | "), " |")
        end
        println(io, "\nOnly complete path-count, pure-MLU samples with runs 1 through 10 are reportable. Restricted waypoint rows are feasible upper bounds, not original-problem optima.")
    end
    mkpath(reportdir)
    tex = joinpath(reportdir, "table_official_P$P.tex")
    open(tex, "w") do io
        println(io, "% generated deterministically by orange/scripts/official_tables.jl")
        println(io, raw"\begin{tabular}{lrrrrrrrlll}")
        println(io, raw"\toprule")
        println(io, raw"Inst & $n$ & $m$ & $|D|$ & MLU & LB & CPU & Gap & Runs & Status & Model \\ \midrule")
        for row in rows
            vals = row[[1, 2, 3, 4, 10, 11, 12, 13, 7, 16, 6]]
            println(io, join(replace.(vals, "_" => raw"\_"), " & "), " \\\\")
        end
        println(io, raw"\bottomrule")
        println(io, raw"\end{tabular}")
    end
    println("wrote $csv, $md and $tex")
end

# Keep the auditable best-known index synchronized with the raw rows used above.
write_best_known(records, joinpath(resdir, "best_known.csv"))
