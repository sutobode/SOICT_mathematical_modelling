using Test, Orange
include(joinpath(@__DIR__, "..", "scripts", "official_common.jl"))

function official_fixture_row(run; mode="pathcount", model="full_arc", mlu=1.0,
                              gap="0.0", artifact_run=run, status="Optimal")
    Dict("run" => string(run), "routing_mode" => mode, "model_type" => model,
         "objective_mode" => "pure_mlu", "experiment" => "official", "time_limit" => "1800.0",
         "P" => "1", "status" => status, "check" => "ok",
         "mlu" => string(mlu), "solve_time" => string(10.0 + run), "nodes" => string(run),
         "pure_mlu_bound" => model == "full_arc" ? string(mlu) : "NaN",
         "pure_mlu_gap" => gap,
         "srpaths_file" => "run$(artifact_run)-srpaths.json",
         "loads_file" => "run$(artifact_run)-loads.csv")
end

@testset "official aggregation isolates routing mode and requires ten runs" begin
    complete = [official_fixture_row(r) for r in 1:10]
    @test summarize_official_rows(complete).complete
    @test !summarize_official_rows(complete[1:9]).complete
    mixed = copy(complete)
    mixed[10] = official_fixture_row(10; mode="ecmp")
    summary = summarize_official_rows(mixed)
    @test !summary.complete
    @test occursin("routing", summary.reason)
end

@testset "weighted bounds are not pure MLU bounds" begin
    @test isnan(pure_mlu_bound("weighted_secondary", 0.4))
    @test pure_mlu_bound("pure_mlu", 0.4) == 0.4
    @test isnan(pure_mlu_gap(0.5, NaN))
    @test pure_mlu_gap(0.5, 0.5) == 0.0
end

@testset "missing gaps are unavailable, not zero" begin
    rows = [official_fixture_row(r; gap="NaN") for r in 1:10]
    summary = summarize_official_rows(rows)
    @test summary.complete
    @test isnan(summary.avg_gap)
end

@testset "best run retains its matching artifact" begin
    rows = [official_fixture_row(r; mlu=(r == 4 ? 0.8 : 1.0)) for r in 1:10]
    summary = summarize_official_rows(rows)
    @test summary.complete
    @test summary.best_row["run"] == "4"
    @test summary.best_row["srpaths_file"] == "run4-srpaths.json"
    @test summary.best_row["loads_file"] == "run4-loads.csv"
end

@testset "official load artifact is independently verified" begin
    out = mktempdir()
    name = "setA-01"
    inst = read_instance(joinpath(SETA, name))
    rs = [build_r(inst, 1; mode=:pathcount)]
    paths = direct_paths(inst, 1)
    mlu = max_utilization(inst, rs, paths, 1)
    srfile = joinpath(out, "run4-srpaths.json")
    loadsfile = joinpath(out, "run4-loads.csv")
    write_srpaths(inst, paths, 1, srfile)
    write_loads(inst, rs, paths, 1, loadsfile;
                run_id=4, instance=name, routing_mode="pathcount")
    row = official_fixture_row(4; mlu=mlu)
    row["instance"] = name
    @test verify_official_artifact(row, out) == "verified"

    lines = readlines(loadsfile)
    arc_row = findfirst(line -> startswith(line, "arc,"), lines)
    fields = split(lines[arc_row], ",")
    fields[6] = string(parse(Float64, fields[6]) + 0.25)
    lines[arc_row] = join(fields, ",")
    write(loadsfile, join(lines, "\n") * "\n")
    @test verify_official_artifact(row, out) == "verification_failed"

    run_rows = [official_fixture_row(r; mlu=(r == 4 ? mlu : mlu + 0.1)) for r in 1:10]
    for run_row in run_rows
        run_row["instance"] = name
        run_row["P"] = "1"
    end
    columns = sort(unique(vcat([collect(keys(run_row)) for run_row in run_rows]...)))
    official_csv = joinpath(out, "setA-01-P1-official.csv")
    open(official_csv, "w") do io
        println(io, join(columns, ","))
        for run_row in run_rows
            println(io, join([run_row[column] for column in columns], ","))
        end
    end
    record = best_known_records(out)[(name, 1)]
    @test record["verification_status"] == "verification_failed"
    @test record["status"] == "UNVERIFIED"
    @test isempty(record["srpaths_file"]) && isempty(record["loads_file"])
    @test !isfile(joinpath(out, "official-artifacts",
                           "setA-01-P1-pathcount-best-run4-loads.csv"))
end

@testset "restricted optimum is not original-problem optimal" begin
    out = mktempdir()
    csv = run_wp_instance(TOY, "toy", 1, 60; outdir=out, r_mode=:pathcount,
                          tag="-official-pc-r1", run_id=1, official=true)
    lines = readlines(csv)
    row = Dict(zip(split(lines[1], ","; keepempty=true), split(lines[2], ","; keepempty=true)))
    @test row["status"] == "Optimal"
    @test row["model_type"] == "restricted_waypoint"
    @test row["objective_mode"] == "pure_mlu"
    @test row["original_problem_optimal"] == "false"
    @test isnan(parse(Float64, row["pure_mlu_bound"]))
    @test isfile(joinpath(out, row["srpaths_file"]))
    @test isfile(joinpath(out, row["loads_file"]))
end
