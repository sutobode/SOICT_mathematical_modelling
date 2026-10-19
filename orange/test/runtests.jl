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

@testset "runner writes csv and survives errors" begin
    out = mktempdir()
    csv = run_instance(TOY, "toy", 2, 60; runs=2, outdir=out)
    lines = readlines(csv)
    @test startswith(lines[1], "instance,P,run,n,m,nD,status,z,mlu,mlu_base")
    @test length(lines) == 3
    @test split(lines[2], ",")[7] == "Optimal"
    @test isfile(joinpath(out, "toy-P2-srpaths.json")) && isfile(joinpath(out, "toy-P2-loads.csv"))
    # instance không tồn tại: ghi ERROR, không ném lỗi
    csv2 = run_instance(joinpath(out, "missing"), "missing", 1, 10; runs=1, outdir=out)
    @test split(readlines(csv2)[2], ",")[7] == "ERROR"
end

@testset "local search" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, p) for p in 1:2]
    paths, mlu = local_search(inst, rs, 1; time_limit=5.0)
    @test mlu <= base_mlu(inst, rs, 1) + 1e-12
    @test mlu >= brute_best(inst, 1) - 1e-9
    @test mlu ≈ max_utilization(inst, rs, paths, 1)
    inst0 = read_instance(TOY; maxseg=2, budget=0)
    paths0, _ = local_search(inst0, rs, 2; time_limit=5.0)
    @test all(d -> paths0[(d, 1)] == paths0[(d, 2)], 1:2)
end

@testset "lex second stage keeps MLU" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, 1)]
    model, x, z, load = build_model(inst, rs, 1, OPT)
    optimize!(model)
    zstar = value(z)
    total1 = sum(value(load[1][a]) / inst.cap[a] for a in 1:inst.m)
    lex_second_stage!(model, z, load, inst, zstar)
    optimize!(model)
    @test termination_status(model) == MOI.OPTIMAL
    @test value(z) <= zstar + 1e-6
    @test sum(value(load[1][a]) / inst.cap[a] for a in 1:inst.m) <= total1 + 1e-6
end

@testset "acyclic model has simple paths only" begin
    inst = read_instance(TOY; budget=2)
    rs = [build_r(inst, p) for p in 1:2]
    model, x, z = build_model(inst, rs, 2, OPT; acyclic=true)
    optimize!(model)
    @test termination_status(model) == MOI.OPTIMAL
    paths = extract_paths(inst, x, 2)
    for d in 1:2, p in 1:2
        nsel = count(v -> value(v) > 0.5, [x[d, p, i, j] for i in 1:inst.n for j in 1:inst.n if i != j])
        @test nsel == length(paths[(d, p)]) - 1               # không có đoạn thừa/chu trình
    end
    @test check_solution(inst, rs, paths, 2, value(z)).budget_ok
end

@testset "degree constraints and scaled eps" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, 1)]
    model, x, z = build_model(inst, rs, 1, OPT)
    @test coefficient(objective_function(model), x[1, 1, 1, 6]) ≈ 1e-7 / 2    # eps = 1e-7/nD
    @test num_constraints(model, AffExpr, MOI.LessThan{Float64}) >=
          2 * inst.n * 2 + 2 + inst.m                                         # in/out degree <= 1 per (d,node), maxSeg, load
end

@testset "runner reports actual gap and objective" begin
    out = mktempdir()
    csv = run_instance(TOY, "toy", 2, 60; runs=1, outdir=out)
    head = split(readlines(csv)[1], ",")
    r = Dict(zip(head, split(readlines(csv)[2], ",")))
    @test haskey(r, "obj")
    zv, obj, gap = parse(Float64, r["z"]), parse(Float64, r["obj"]), parse(Float64, r["gap"])
    @test obj >= zv - 1e-12
    @test 0.0 <= gap < 1e-5                                    # gap thật, không phải 0 cố định
end

@testset "warm start from given paths" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, p) for p in 1:2]
    wp = Dict((1, 1) => [1, 5, 6], (2, 1) => [3, 6], (1, 2) => [1, 5, 6], (2, 2) => [3, 6])
    model, x, z = build_model(inst, rs, 2, OPT; start_paths=wp)
    @test start_value(x[1, 1, 1, 5]) == 1.0 && start_value(x[1, 1, 5, 6]) == 1.0
    @test start_value(x[1, 1, 1, 6]) == 0.0
    @test start_value(z) ≈ max_utilization(inst, rs, wp, 2)
    optimize!(model)
    @test value(z) <= max_utilization(inst, rs, wp, 2) + 1e-9
end

@testset "runner uses heuristic start" begin
    out = mktempdir()
    csv = run_instance(TOY, "toy", 2, 60; runs=1, outdir=out)
    head = split(readlines(csv)[1], ",")
    row = Dict(zip(head, split(readlines(csv)[2], ",")))
    @test haskey(row, "start_time") && haskey(row, "start_mlu")
    @test parse(Float64, row["start_mlu"]) >= parse(Float64, row["z"]) - 1e-9    # MILP no worse than its start
    @test parse(Float64, row["start_mlu"]) <= parse(Float64, row["mlu_base"]) + 1e-9
end

@testset "slow instances get slow_runs runs, fast get all runs" begin
    out = mktempdir()
    slow = run_instance(TOY, "toy", 2, 60; runs=5, fast_threshold=0.0, slow_runs=3, outdir=out)
    @test length(readlines(slow)) == 1 + 3
    fast = run_instance(TOY, "toy", 2, 60; runs=5, fast_threshold=1e6, slow_runs=3, outdir=out)
    @test length(readlines(fast)) == 1 + 5
end

@testset "candidates: K smallest detours, valid in all periods" begin
    inst = read_instance(TOY)
    rs = [build_r(inst, p) for p in 1:2]
    C = candidates(inst, rs, 2)
    @test length(C) == 2 && all(c -> c[1] == 0 && length(c) <= 3, C)       # 0 = không waypoint, tối đa K=2 ứng viên
    for d in 1:2, w in C[d][2:end]
        @test w != inst.dem_s[d] && w != inst.dem_t[d]
        @test all(p -> haskey(rs[p], (inst.dem_s[d], w)) && haskey(rs[p], (w, inst.dem_t[d])), 1:2)
    end
    Call = candidates(inst, rs, 100)                                         # K lớn: mọi nút hợp lệ
    @test length(Call[1]) == 1 + (inst.n - 2)
end

@testset "waypoint model equals brute force (K=all)" begin
    for b in (0, 3, 20), P in (1, 2)
        inst = read_instance(TOY; maxseg=2, budget=b)
        rs = [build_r(inst, p) for p in 1:P]
        model, y, C = build_wp_model(inst, rs, P, OPT; K=100)
        optimize!(model)
        @test termination_status(model) == MOI.OPTIMAL
        zstar = objective_value(model)
        @test zstar ≈ brute_best(inst, P) atol = 1e-5
        paths = extract_wp_paths(inst, y, C, P)
        chk = check_solution(inst, rs, paths, P, zstar + 1e-5)
        @test chk.budget_ok
    end
end

@testset "waypoint model warm start and restricted candidates" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, p) for p in 1:2]
    wp = Dict((1, 1) => [1, 5, 6], (2, 1) => [3, 6], (1, 2) => [1, 5, 6], (2, 2) => [3, 6])
    model, y, C = build_wp_model(inst, rs, 2, OPT; K=3, start_paths=wp)
    c1 = findfirst(==([5]), C[1])
    @test c1 !== nothing && start_value(y[1][1][c1]) == 1.0                 # waypoint v4 phải nằm trong ứng viên và được dùng làm khởi tạo
    optimize!(model)
    @test objective_value(model) <= max_utilization(inst, rs, wp, 2) + 1e-6
    restricted = objective_value(model)
    full_model, _, _ = build_wp_model(inst, rs, 2, OPT; K=100)
    optimize!(full_model)
    @test objective_value(full_model) <= restricted + 1e-9                   # nhiều ứng viên hơn không tệ hơn
end

@testset "start waypoint is always a candidate" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, p) for p in 1:2]
    wp = Dict((1, 1) => [1, 5, 6], (2, 1) => [3, 6], (1, 2) => [1, 5, 6], (2, 2) => [3, 6])
    model, y, C = build_wp_model(inst, rs, 2, OPT; K=0, start_paths=wp)      # K=0: chỉ "không waypoint"
    @test [5] in C[1] && C[2] == [Int[]]
    c = findfirst(==([5]), C[1])
    @test start_value(y[1][1][c]) == 1.0 && start_value(y[1][2][c]) == 1.0
    optimize!(model)
    @test objective_value(model) <= max_utilization(inst, rs, wp, 2) + 1e-6
end

@testset "waypoint runner writes csv with adaptive K" begin
    out = mktempdir()
    csv = run_wp_instance(TOY, "toy", 2, 60; outdir=out)
    head = split(readlines(csv)[1], ",")
    r = Dict(zip(head, split(readlines(csv)[2], ",")))
    @test r["status"] == "Optimal" && r["check"] == "ok"
    @test parse(Float64, r["mlu"]) <= parse(Float64, r["heur_mlu"]) + 1e-9
    @test parse(Float64, r["heur_mlu"]) <= parse(Float64, r["mlu_base"]) + 1e-9
    @test parse(Int, r["K"]) == 5                                  # n=7 nút: K = n-2 ứng viên mỗi demand
    @test isfile(joinpath(out, "toy-wp-P2-srpaths.json"))
    # giới hạn kích thước: K giảm khi vượt max_binaries
    csv2 = run_wp_instance(TOY, "toy", 2, 60; outdir=out, max_binaries=2 * 2 * 3, tag="-small")
    r2 = Dict(zip(split(readlines(csv2)[1], ","), split(readlines(csv2)[2], ",")))
    @test parse(Int, r2["K"]) == 2                                 # (nD*P*(K+1)) <= max_binaries -> K=2
    # lỗi đọc dữ liệu: ghi ERROR, không ném
    csv3 = run_wp_instance(joinpath(out, "missing"), "missing", 1, 10; outdir=out)
    @test split(readlines(csv3)[2], ",")[8] == "ERROR"
end

# vét cạn với tối đa 2 waypoint mỗi demand (tương ứng maxSeg = 3)
function brute2_best(inst, P)
    n, nD = inst.n, length(inst.dem_s)
    rs = [build_r(inst, p) for p in 1:P]
    seq(d, w) = vcat(inst.dem_s[d], w, inst.dem_t[d])
    opts = [vcat([Int[]], [[w] for w in 1:n if w != inst.dem_s[d] && w != inst.dem_t[d]],
                 [[a, b] for a in 1:n for b in 1:n if a != b && a != inst.dem_s[d] && a != inst.dem_t[d] &&
                  b != inst.dem_s[d] && b != inst.dem_t[d]]) for d in 1:nD]
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

@testset "waypoint model with pairs equals brute force (maxSeg=3)" begin
    for (b, P) in ((20, 1), (3, 2))
        inst = read_instance(TOY; maxseg=3, budget=b)
        rs = [build_r(inst, p) for p in 1:P]
        model, y, W = build_wp_model(inst, rs, P, OPT; K=100, K2=100)
        optimize!(model)
        @test termination_status(model) == MOI.OPTIMAL
        z2 = objective_value(model)
        @test z2 ≈ brute2_best(inst, P) atol = 1e-5
        single, _, _ = build_wp_model(inst, rs, P, OPT; K=100)
        optimize!(single)
        @test z2 <= objective_value(single) + 1e-6               # thêm cặp waypoint không tệ hơn (HiGHS mip_abs_gap = 1e-6)
        paths = extract_wp_paths(inst, y, W, P)
        @test all(length(paths[(d, p)]) <= 4 for d in 1:2, p in 1:P)
        @test check_solution(inst, rs, paths, P, z2 + 1e-5).budget_ok
    end
end

@testset "single-waypoint budget uses the compact formulation" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, p) for p in 1:2]
    model, y, W = build_wp_model(inst, rs, 2, OPT; K=100)
    nW = sum(length.(W))
    @test num_variables(model) == 2 * nW + 1 + nW        # y (2 kỳ) + z + st (1 biến mỗi phương án)
    # công thức tổng quát (có cặp waypoint) vẫn đúng: số biến lớn hơn rõ rệt
    model2, _, W2 = build_wp_model(inst, rs, 2, OPT; K=100, K2=100)
    @test num_variables(model2) > 2 * sum(length.(W2)) + 1
end

function lp_value_full(inst, rs, P)
    model, y, W = build_wp_model(inst, rs, P, OPT; K=inst.n)
    relax_integrality(model)
    optimize!(model)
    return objective_value(model)
end

@testset "column generation reaches the full LP value (P=1)" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, 1)]
    C, lp, iters = colgen(inst, rs, 1; K0=0)
    @test all(c -> c[1] == 0, C)
    @test lp ≈ lp_value_full(inst, rs, 1) atol = 1e-6          # hội tụ về LP của mô hình đầy đủ
    @test iters >= 1
    # MILP trên các cột sinh ra có cùng nghiệm tối ưu với mô hình đầy đủ
    model, y, W = build_wp_model(inst, rs, 1, OPT; cands=C)
    optimize!(model)
    @test objective_value(model) ≈ brute_best(inst, 1) atol = 1e-5
end

@testset "column generation on a real instance finds the optimum with few candidates" begin
    inst = read_instance(joinpath(SETA, "setA-04"))
    rs = [build_r(inst, 1)]
    C, lp, iters = colgen(inst, rs, 1; K0=2, max_iter=40)
    @test sum(length.(C)) < 0.5 * length(inst.dem_s) * (inst.n - 1)          # ít cột hơn nhiều so với đầy đủ
    model, y, W = build_wp_model(inst, rs, 1, OPT; cands=C)
    optimize!(model)
    @test objective_value(model) ≈ 0.45912 atol = 1e-4                      # tối ưu mô hình đầy đủ (đã đo)
    @test lp <= objective_value(model) + 1e-9                               # cận dưới hợp lệ
end

@testset "column generation with budget (P=2) returns valid candidates" begin
    inst = read_instance(TOY; maxseg=2, budget=3)
    rs = [build_r(inst, p) for p in 1:2]
    C, lp, iters = colgen(inst, rs, 2; K0=0)
    for d in 1:2, w in C[d][2:end]
        @test all(p -> haskey(rs[p], (inst.dem_s[d], w)) && haskey(rs[p], (w, inst.dem_t[d])), 1:2)
    end
    model, y, W = build_wp_model(inst, rs, 2, OPT; cands=C)
    optimize!(model)
    @test termination_status(model) == MOI.OPTIMAL
    @test objective_value(model) <= base_mlu(inst, rs, 2) + 1e-9
end

@testset "waypoint runner with column generation" begin
    out = mktempdir()
    plain = run_wp_instance(TOY, "toy", 1, 60; outdir=out)
    cg = run_wp_instance(TOY, "toy", 1, 60; outdir=out, use_colgen=true, K0=0, tag="-cg")
    rp = Dict(zip(split(readlines(plain)[1], ","), split(readlines(plain)[2], ",")))
    rc = Dict(zip(split(readlines(cg)[1], ","), split(readlines(cg)[2], ",")))
    @test rc["status"] == "Optimal" && rc["check"] == "ok"
    @test parse(Float64, rc["mlu"]) ≈ parse(Float64, rp["mlu"]) atol = 1e-6          # cùng nghiệm tối ưu
    @test parse(Float64, rc["cg_lp"]) <= parse(Float64, rc["obj"]) + 1e-9            # cận dưới hợp lệ (P=1)
    @test parse(Int, rc["cg_iters"]) >= 1
    @test parse(Int, rc["binaries"]) <= parse(Int, rp["binaries"])
end

lexcmp_leq(a, b; tol=1e-7) = begin
    for (x, y) in zip(a, b)
        x < y - tol && return true
        x > y + tol && return false
    end
    true
end

sorted_loads(inst, rs, paths, P) = sort(vcat([utilization(inst, rs, paths, p)[[a for a in 1:inst.m if !(a in inst.down[p])]] for p in 1:P]...); rev=true)

@testset "lexicographic refinement never worsens the sorted load vector" begin
    for (b, P) in ((20, 1), (20, 2), (3, 2))
        inst = read_instance(TOY; maxseg=2, budget=b)
        rs = [build_r(inst, p) for p in 1:P]
        model, y, W = build_wp_model(inst, rs, P, OPT; K=inst.n)
        optimize!(model)
        base_paths = extract_wp_paths(inst, y, W, P)
        zstar = maximum(sorted_loads(inst, rs, base_paths, P))
        paths, levels = lex_refine(inst, rs, P, OPT; K=inst.n, levels=6, start_paths=base_paths)
        v0, v1 = sorted_loads(inst, rs, base_paths, P), sorted_loads(inst, rs, paths, P)
        @test v1[1] ≈ zstar atol = 1e-6                              # mức đầu giữ nguyên
        @test lexcmp_leq(v1, v0)
        @test levels >= 1
        @test check_solution(inst, rs, paths, P, zstar + 1e-5).budget_ok
    end
end


@testset "choose_K fits the memory budget" begin
    per_binary = Orange.wp_bytes_per_binary(10.0)
    @test per_binary == 2 * 10.0 * 100 + 800
    # nD=2, P=2: mỗi tăng K thêm 4 nhị phân; ngân sách vừa đủ 12 nhị phân => K=2
    @test Orange.choose_K(2, 2, 5, 10.0, 12 * per_binary) == 2
    @test Orange.choose_K(2, 2, 5, 10.0, 1e12) == 5                 # đủ RAM: lấy mọi nút (n-2)
    @test Orange.choose_K(2, 2, 5, 10.0, 3 * per_binary) === nothing  # không đủ cho cả K=0 (4 nhị phân)
end

@testset "waypoint runner skips instead of exhausting memory" begin
    out = mktempdir()
    csv = run_wp_instance(TOY, "toy", 2, 60; outdir=out, mem_budget_bytes=1.0)
    r = Dict(zip(split(readlines(csv)[1], ","), split(readlines(csv)[2], ",")))
    @test r["status"] == "SKIPPED_LOW_MEMORY"
    @test length(split(readlines(csv)[2], ",")) == length(split(readlines(csv)[1], ","))
    csv2 = run_wp_instance(TOY, "toy", 2, 60; outdir=out, mem_budget_bytes=1e12, tag="-ok")
    @test Dict(zip(split(readlines(csv2)[1], ","), split(readlines(csv2)[2], ",")))["status"] == "Optimal"
end

@testset "column enrichment adds the lowest reduced-cost columns" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, 1)]
    C0, lp0, _ = colgen(inst, rs, 1; K0=0)
    C2, lp2, _ = colgen(inst, rs, 1; K0=0, extra=2)
    @test all(length(C2[d]) >= length(C0[d]) for d in 1:2)
    @test any(length(C2[d]) > length(C0[d]) for d in 1:2)
    @test all(length(C2[d]) <= length(C0[d]) + 2 for d in 1:2)
    @test lp2 ≈ lp0 atol = 1e-9                              # làm giàu không đổi cận dưới LP
    model, y, W = build_wp_model(inst, rs, 1, OPT; cands=C2)
    optimize!(model)
    @test objective_value(model) ≈ brute_best(inst, 1) atol = 1e-5
end

@testset "LNS never worsens the start and reaches the optimum when everything is free" begin
    for (b, P) in ((20, 1), (3, 2))
        inst = read_instance(TOY; maxseg=2, budget=b)
        rs = [build_r(inst, p) for p in 1:P]
        start = direct_paths(inst, P)
        base = max_utilization(inst, rs, start, P)
        paths, mlu = lns(inst, rs, P, OPT; K=inst.n, start_paths=start, iters=1, frac=1.0)
        @test mlu <= base + 1e-9
        @test mlu ≈ brute_best(inst, P) atol = 1e-5                 # mọi demand tự do => một vòng giải chính xác
        @test check_solution(inst, rs, paths, P, mlu + 1e-6).budget_ok
        paths2, mlu2 = lns(inst, rs, P, OPT; K=inst.n, start_paths=start, iters=5, frac=0.5, seed=3)
        @test mlu2 <= base + 1e-9 && mlu2 >= brute_best(inst, P) - 1e-5
        @test check_solution(inst, rs, paths2, P, mlu2 + 1e-6).budget_ok
    end
end

@testset "frozen demands keep their start choice" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, 1)]
    start = Dict((1, 1) => [1, 5, 6], (2, 1) => [3, 6])
    model, y, W = build_wp_model(inst, rs, 1, OPT; K=inst.n, start_paths=start, freeze=[1])
    optimize!(model)
    @test extract_wp_paths(inst, y, W, 1)[(1, 1)] == [1, 5, 6]      # demand 1 bị đóng băng
end
