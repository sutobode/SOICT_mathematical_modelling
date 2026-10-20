using Test, Orange

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
