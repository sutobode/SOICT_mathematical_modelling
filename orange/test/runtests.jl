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

@testset "ecmp toy (Bảng 2 của đề)" begin
    inst = read_instance(TOY)
    R = routing(inst, 1)
    f = ecmp_split(inst, R, 1, 6)                        # v0 -> v5
    @test f[arc(inst, 0)] ≈ 1.0                          # a0,1
    @test f[arc(inst, 2)] ≈ 0.5                          # a1,3
    @test f[arc(inst, 3)] ≈ 0.5                          # a1,4
    @test f[arc(inst, 6)] ≈ 0.75                         # a3,5
    @test f[arc(inst, 18)] ≈ 0.25                        # a4,3
    @test f[arc(inst, 9)] ≈ 0.25                         # a4,6
    @test f[arc(inst, 21)] ≈ 0.25                        # a6,5 (id 21: 6->5)
    g = ecmp_split(inst, R, 3, 6)                        # v2 -> v5
    @test g[arc(inst, 4)] ≈ 1.0 && g[arc(inst, 9)] ≈ 0.5
    @test (f[arc(inst, 9)] * 50 + g[arc(inst, 9)] * 100) / 200 ≈ 0.3125
end

@testset "pathcount toy (calculating_r.pdf)" begin
    inst = read_instance(TOY)
    f = pathcount_split(inst, routing(inst, 1), 1, 6)
    @test f[arc(inst, 0)] ≈ 1.0
    @test f[arc(inst, 3)] ≈ 2 / 3                        # khác ECMP (0.5)
    @test f[arc(inst, 2)] ≈ 1 / 3
    r = build_r(inst, 1; mode=:pathcount)
    @test Dict(r[(1, 6)])[arc(inst, 3)] ≈ 2 / 3
    @test_throws ErrorException build_r(inst, 1; mode=:other)
end

@testset "ecmp down arcs" begin
    inst = read_instance(TOY)
    f = ecmp_split(inst, routing(inst, 2), 1, 6)         # a1,3 và a1,4 bị tắt
    @test !haskey(f, arc(inst, 2)) && !haskey(f, arc(inst, 3))
    @test !isempty(f)
    r = build_r(inst, 2)
    @test all(q -> !(first(q) in inst.down[2]), (q for lst in values(r) for q in lst))
end

@testset "ecmp float ties" begin
    dir = mktempdir()
    write(joinpath(dir, "t-net.json"), """{"directed":true,"multigraph":true,"graph":{},
      "nodes":[{"name":"a","id":0},{"name":"b","id":1},{"name":"c","id":2},{"name":"d","id":3}],
      "links":[{"id":0,"from":0,"to":1,"metric":0.1,"capacity":1},{"id":1,"from":1,"to":3,"metric":0.2,"capacity":1},
               {"id":2,"from":0,"to":2,"metric":0.15,"capacity":1},{"id":3,"from":2,"to":3,"metric":0.15,"capacity":1}]}""")
    write(joinpath(dir, "t-tm.json"), """{"num_time_slots":1,"demands":[{"v":[1.0],"s":0,"t":3}]}""")
    write(joinpath(dir, "t-scenario.json"), """{"max_segments":2,"budget":[],"interventions":[]}""")
    inst = read_instance(joinpath(dir, "t"))
    f = ecmp_split(inst, routing(inst, 1), 1, 4)
    # 0.1+0.2 = 0.30000000000000004 và 0.15+0.15 = 0.3 phải hòa: 4 cung, mỗi cung 0.5
    @test length(f) == 4 && all(≈(0.5), values(f))
end
