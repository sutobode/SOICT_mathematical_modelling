using Test, Orange, JuMP, HiGHS

const LEX_OPT = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.0,
                                          "mip_abs_gap" => 0.0, "threads" => 1)

function lex_preference_model(a, b)
    model = Model(LEX_OPT)
    set_silent(model)
    @variable(model, choose_b, Bin)
    loads = [@expression(model, a[i] + (b[i] - a[i]) * choose_b) for i in eachindex(a)]
    inst = Instance(3, 3, collect(1:3), [1, 2, 3], [2, 3, 1], collect(1:3),
                    ones(3), ones(3), [1], [2], reshape([1.0], 1, 1), 1, 1,
                    [Inf], [Int[]])
    result = exact_lexicographic_loads!(model, [loads], inst)
    return value(choose_b), result
end

@testset "exact lexicographic loads prefer the smaller second rank" begin
    a = [0.90, 0.80, 0.30]
    b = [0.90, 0.50, 0.45]
    choice, result = lex_preference_model(a, b)
    @test choice > 0.5
    @test result.values ≈ sort(b; rev=true) atol=1e-9
    @test result.active_links == [(1, 1), (1, 2), (1, 3)]
end

@testset "exact lexicographic loads reach the third rank after two ties" begin
    a = [0.90, 0.80, 0.45]
    b = [0.80, 0.90, 0.30]
    choice, result = lex_preference_model(a, b)
    @test choice > 0.5
    @test result.values ≈ sort(b; rev=true) atol=1e-9
end

@testset "acyclic exact lexicographic solution excludes disconnected cycles" begin
    dir = mktempdir()
    prefix = joinpath(dir, "cycle")
    write(prefix * "-net.json", """{"directed":true,"multigraph":false,
      "nodes":[{"name":"s","id":0},{"name":"t","id":1},{"name":"a","id":2},{"name":"b","id":3}],
      "links":[{"id":0,"from":0,"to":1,"metric":1,"capacity":10},
               {"id":1,"from":2,"to":3,"metric":1,"capacity":10},
               {"id":2,"from":3,"to":2,"metric":1,"capacity":10}]}""")
    write(prefix * "-tm.json", """{"num_time_slots":1,"demands":[{"v":[1.0],"s":0,"t":1}]}""")
    write(prefix * "-scenario.json", """{"max_segments":3,"budget":[],"interventions":[]}""")
    inst = read_instance(prefix)
    rs = [build_r(inst, 1; mode=:pathcount)]

    cyclic, cx, _, cload = build_model(inst, rs, 1, LEX_OPT; acyclic=false)
    @constraint(cyclic, cx[1, 1, 3, 4] == 1)
    @constraint(cyclic, cx[1, 1, 4, 3] == 1)
    exact_lexicographic_loads!(cyclic, cload, inst)
    @test termination_status(cyclic) == JuMP.MOI.OPTIMAL
    @test value(cx[1, 1, 3, 4]) > 0.5 && value(cx[1, 1, 4, 3]) > 0.5

    acyclic, ax, _, aload = build_model(inst, rs, 1, LEX_OPT; acyclic=true)
    @constraint(acyclic, ax[1, 1, 3, 4] == 1)
    @constraint(acyclic, ax[1, 1, 4, 3] == 1)
    @test_throws ErrorException exact_lexicographic_loads!(acyclic, aload, inst)
end

@testset "P1 and finite-budget P2 lexicographic exports match the optimized model" begin
    dir = mktempdir()
    prefix = joinpath(dir, "lex")
    write(prefix * "-net.json", """{"directed":true,"multigraph":false,
      "nodes":[{"name":"s","id":0},{"name":"a","id":1},{"name":"b","id":2},{"name":"t","id":3}],
      "links":[{"id":0,"from":0,"to":1,"metric":1,"capacity":20},
               {"id":1,"from":1,"to":3,"metric":1,"capacity":20},
               {"id":2,"from":0,"to":2,"metric":1,"capacity":10},
               {"id":3,"from":2,"to":3,"metric":1,"capacity":10}]}""")
    write(prefix * "-tm.json", """{"num_time_slots":2,"demands":[{"v":[10.0,10.0],"s":0,"t":3}]}""")
    write(prefix * "-scenario.json", """{"max_segments":2,"budget":[{"t":1,"value":4}],
      "interventions":[{"t":1,"links":[0]}]}""")
    inst = read_instance(prefix)
    for P in (1, 2)
        rs = [build_r(inst, p; mode=:pathcount) for p in 1:P]
        model, x, _, load = build_model(inst, rs, P, LEX_OPT; eps=0.0, acyclic=true)
        result = exact_lexicographic_loads!(model, load, inst)
        @test termination_status(model) == JuMP.MOI.OPTIMAL
        paths = extract_paths(inst, x, P)
        chk = check_lexicographic_solution(inst, rs, paths, P, x, load, result)
        @test chk.mlu ≈ first(result.values) atol=1e-6
        @test chk.budget_ok
        if P == 2
            @test chk.budget_changes[2] == 3
            @test chk.budget_changes[2] <= inst.budget[2]
            @test paths[(1, 1)] == [1, 2, 4]
            @test paths[(1, 2)] == [1, 4]
            @test 1 in inst.down[2]
        end
        file = tempname() * ".json"
        write_srpaths(inst, paths, P, file)
        exported = read_srpaths(inst, file, P)
        @test check_lexicographic_solution(inst, rs, exported, P, x, load, result).budget_changes ==
              chk.budget_changes
    end
end
