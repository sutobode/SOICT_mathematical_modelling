using Test, Orange, JuMP, HiGHS
const TOY = joinpath(@__DIR__, "toy", "toy")
const SETA = joinpath(@__DIR__, "..", "..", "project", "setA")
const OPT = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.0, "threads" => 1)
arc(inst, id) = findfirst(==(id), inst.link_id)

@testset "io" begin
    inst = read_instance(TOY)
    @test inst.n == 7 && inst.m == 22 && inst.P == 2 && inst.maxseg == 4
    @test inst.vol == [50.0 100.0; 100.0 50.0]
    @test inst.dem_s == [1, 3] && inst.dem_t == [6, 6]      # id JSON + 1
    @test inst.budget[1] == Inf && inst.budget[2] == 20
    @test inst.down[1] == Int[] && inst.down[2] == [3, 4]   # link id 2,3 -> chỉ số 3,4
    @test read_instance(TOY; maxseg=2).maxseg == 2
    @test read_instance(TOY; budget=0).budget[2] == 0
    @test read_instance(TOY; budget=Inf).budget[2] == Inf
end

@testset "setA readable (kể cả multigraph=true)" begin
    for i in 1:20
        inst = read_instance(joinpath(SETA, "setA-" * lpad(i, 2, '0')))
        @test inst.P == 2 && inst.maxseg == 6
        @test length(inst.down[2]) == 1 && isfinite(inst.budget[2])
        @test all(inst.omega .> 0) && all(inst.cap .> 0)
    end
end
