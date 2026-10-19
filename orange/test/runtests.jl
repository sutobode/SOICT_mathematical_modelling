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

@testset "changes (Bảng 1 của đề)" begin
    @test changes([1, 9, 2], [1, 2]) == 3
    @test changes([1, 5, 6, 2], [1, 5, 2]) == 3
    @test changes([1, 5, 6, 2], [1, 6, 5, 2]) == 6
    @test changes([1, 5, 2], [1, 6, 2]) == 4
end

@testset "toy loads from paths" begin
    inst = read_instance(TOY)
    rs = [build_r(inst, p) for p in 1:2]
    @test base_mlu(inst, rs[1:1], 1) ≈ 0.4375
    wp = Dict((1, 1) => [1, 5, 6], (2, 1) => [3, 6])     # waypoint v4 (chỉ số 5) cho d0
    @test max_utilization(inst, rs, wp, 1) ≈ 0.375
end

# vét cạn: mỗi demand đi thẳng hoặc qua đúng 1 waypoint (tương ứng maxSeg = 2)
function brute_best(inst, P)
    n, nD = inst.n, length(inst.dem_s)
    rs = [build_r(inst, p) for p in 1:P]
    seq(d, w) = w == 0 ? [inst.dem_s[d], inst.dem_t[d]] : [inst.dem_s[d], w, inst.dem_t[d]]
    opts = [[w for w in 0:n if w == 0 || (w != inst.dem_s[d] && w != inst.dem_t[d])] for d in 1:nD]
    joint = collect(Iterators.product(opts...))
    u = [[maximum(utilization(inst, rs, Dict((d, p) => seq(d, c[d]) for d in 1:nD), p)) for c in joint] for p in 1:P]
    best = Inf
    for (i0, c0) in enumerate(joint)
        if P == 1
            best = min(best, u[1][i0]); continue
        end
        for (i1, c1) in enumerate(joint)
            ch = sum(changes(seq(d, c0[d]), seq(d, c1[d])) for d in 1:nD)
            ch <= inst.budget[2] && (best = min(best, max(u[1][i0], u[2][i1])))
        end
    end
    return best
end

@testset "model t=0 equals brute force (maxSeg=2)" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, 1)]
    model, x, z = build_model(inst, rs, 1, OPT)
    @test start_value(x[1, 1, 1, 6]) == 1.0                  # khởi tạo = đi thẳng
    @test start_value(z) ≈ 0.4375
    optimize!(model)
    @test termination_status(model) == MOI.OPTIMAL
    @test value(z) ≈ brute_best(inst, 1) atol = 1e-6
    @test value(z) <= 0.375 + 1e-9
end

@testset "zero-volume demand is fixed to direct path" begin
    dir = mktempdir()
    for f in ("net", "scenario"); cp(TOY * "-$f.json", joinpath(dir, "z-$f.json")); end
    write(joinpath(dir, "z-tm.json"), """{"num_time_slots":2,"demands":[{"v":[0.0,0.0],"s":0,"t":5},{"v":[100.0,50.0],"s":2,"t":5}]}""")
    inst = read_instance(joinpath(dir, "z"); maxseg=2)
    rs = [build_r(inst, p) for p in 1:2]
    model, x, z = build_model(inst, rs, 2, OPT)
    @test is_fixed(x[1, 1, 1, 6]) && fix_value(x[1, 1, 1, 6]) == 1.0
    optimize!(model)
    @test termination_status(model) == MOI.OPTIMAL
    @test value(z) ≈ brute_best(inst, 2) atol = 1e-6
end

@testset "unreachable segments are forbidden" begin
    dir = mktempdir()
    write(joinpath(dir, "l-net.json"), """{"directed":true,"multigraph":false,
      "nodes":[{"name":"a","id":0},{"name":"b","id":1},{"name":"c","id":2}],
      "links":[{"id":0,"from":0,"to":1,"metric":1,"capacity":10},{"id":1,"from":1,"to":2,"metric":1,"capacity":10}]}""")
    write(joinpath(dir, "l-tm.json"), """{"num_time_slots":1,"demands":[{"v":[5.0],"s":0,"t":2}]}""")
    write(joinpath(dir, "l-scenario.json"), """{"max_segments":3,"budget":[],"interventions":[]}""")
    inst = read_instance(joinpath(dir, "l"))
    model, x, z = build_model(inst, [build_r(inst, 1)], 1, OPT)
    @test is_fixed(x[1, 1, 3, 1]) && fix_value(x[1, 1, 3, 1]) == 0.0
    optimize!(model)
    @test value(z) ≈ 0.5
    @test extract_paths(inst, x, 1)[(1, 1)] in ([1, 3], [1, 2, 3])
end

@testset "extract_paths ignores cycles" begin
    inst = read_instance(TOY)
    rs = [build_r(inst, 1)]
    model, x, z = build_model(inst, rs, 1, OPT)
    # d1: đường 1->2->6, cộng chu trình rời 3<->4 và chu trình 2<->4 chạm vào đường
    fake = Dict(x[1, 1, 1, 2] => 1.0, x[1, 1, 2, 6] => 1.0,
                x[1, 1, 3, 4] => 1.0, x[1, 1, 4, 3] => 1.0,
                x[1, 1, 2, 4] => 1.0, x[1, 1, 4, 2] => 1.0,
                x[2, 1, 3, 6] => 1.0)
    paths = extract_paths(inst, x, 1; val=v -> get(fake, v, 0.0))
    @test paths[(1, 1)] == [1, 2, 6]
    @test paths[(2, 1)] == [3, 6]
end

@testset "solution check, srpaths, loads (t=0,1)" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, p) for p in 1:2]
    model, x, z = build_model(inst, rs, 2, OPT)
    optimize!(model)
    @test termination_status(model) == MOI.OPTIMAL
    paths = extract_paths(inst, x, 2)
    chk = check_solution(inst, rs, paths, 2, value(z))
    @test chk.budget_ok
    @test chk.mlu ≈ value(z) atol = 1e-6
    @test value(z) ≈ brute_best(inst, 2) atol = 1e-6
    f = tempname() * ".json"
    write_srpaths(inst, paths, 2, f)
    js = Orange.JSON3.read(read(f, String))
    @test all(e -> e.t in (0, 1) && e.d in (0, 1) && !isempty(e.w), js.srpaths)
    g = tempname() * ".csv"
    write_loads(inst, rs, paths, 2, g)
    lines = readlines(g)
    @test lines[1] == "rank,base,opt"
    @test parse(Float64, split(lines[2], ",")[2]) ≈ base_mlu(inst, rs, 2)
    @test_throws ErrorException check_solution(inst, rs, paths, 2, value(z) - 0.1)
end

@testset "budget 0 forces identical routing" begin
    inst = read_instance(TOY; maxseg=2, budget=0)
    rs = [build_r(inst, p) for p in 1:2]
    model, x, z = build_model(inst, rs, 2, OPT)
    optimize!(model)
    paths = extract_paths(inst, x, 2)
    @test all(d -> paths[(d, 1)] == paths[(d, 2)], 1:2)
    @test value(z) ≈ brute_best(inst, 2) atol = 1e-6
end

@testset "toy t=0,1 with maxSeg=4 (có thể có chu trình)" begin
    inst = read_instance(TOY)
    rs = [build_r(inst, p) for p in 1:2]
    model, x, z = build_model(inst, rs, 2, OPT; tlimit=120)
    optimize!(model)
    @test termination_status(model) == MOI.OPTIMAL
    paths = extract_paths(inst, x, 2)
    chk = check_solution(inst, rs, paths, 2, value(z))
    @test chk.budget_ok
    @test chk.mlu <= base_mlu(inst, rs, 2) + 1e-9
    @test chk.mlu <= brute_best(read_instance(TOY; maxseg=2), 2) + 1e-6   # nhiều đoạn hơn không tệ hơn
end

@testset "setA-01 smoke (t=0)" begin
    inst = read_instance(joinpath(SETA, "setA-01"))
    rs = [build_r(inst, 1)]
    model, x, z = build_model(inst, rs, 1, OPT; tlimit=120)
    t = @elapsed optimize!(model)
    @info "setA-01 t=0" termination_status(model) value(z) base_mlu(inst, rs, 1) t
    @test has_values(model)
    chk = check_solution(inst, rs, extract_paths(inst, x, 1), 1, value(z); tol=1e-5)
    @test chk.mlu <= base_mlu(inst, rs, 1) + 1e-9
end
