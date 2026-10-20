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
