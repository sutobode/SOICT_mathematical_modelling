using Test, Orange, JuMP, HiGHS
const TOY = joinpath(@__DIR__, "toy", "toy")
const SETA = joinpath(@__DIR__, "..", "..", "project", "setA")
const OPT = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.0, "threads" => 1)
arc(inst, id) = findfirst(==(id), inst.link_id)
