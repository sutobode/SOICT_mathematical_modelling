struct Instance
    n::Int
    m::Int
    node_id::Vector{Int}
    arc_from::Vector{Int}
    arc_to::Vector{Int}
    link_id::Vector{Int}
    omega::Vector{Float64}
    cap::Vector{Float64}
    dem_s::Vector{Int}
    dem_t::Vector{Int}
    vol::Matrix{Float64}
    P::Int
    maxseg::Int
    budget::Vector{Float64}
    down::Vector{Vector{Int}}
end

function read_instance(prefix::AbstractString; maxseg=nothing, budget=nothing)
    net = JSON3.read(read(prefix * "-net.json", String))
    tm = JSON3.read(read(prefix * "-tm.json", String))
    sc = JSON3.read(read(prefix * "-scenario.json", String))

    node_id = Int[Int(x.id) for x in net.nodes]
    allunique(node_id) || error("duplicate node ids")
    v_of = Dict(id => k for (k, id) in enumerate(node_id))

    links = net.links
    link_id = Int[Int(l.id) for l in links]
    allunique(link_id) || error("duplicate link ids")
    arc_from = Int[v_of[Int(l["from"])] for l in links]
    arc_to = Int[v_of[Int(l["to"])] for l in links]
    any(arc_from .== arc_to) && error("self loops are not supported")
    omega = Float64[Float64(l.metric) for l in links]
    cap = Float64[Float64(l.capacity) for l in links]
    arc_of_link = Dict(id => a for (a, id) in enumerate(link_id))

    P = Int(tm.num_time_slots)
    dems = tm.demands
    dem_s = Int[v_of[Int(d.s)] for d in dems]
    dem_t = Int[v_of[Int(d.t)] for d in dems]
    vol = zeros(length(dems), P)
    for (k, d) in enumerate(dems), p in 1:P
        vol[k, p] = Float64(d.v[p])
    end

    bud = fill(Inf, P)
    for b in sc.budget
        bud[Int(b.t) + 1] = Float64(b.value)
    end
    budget === nothing || (bud[2:end] .= Float64(budget))

    down = [Int[] for _ in 1:P]
    for iv in sc.interventions, id in iv.links
        push!(down[Int(iv.t) + 1], arc_of_link[Int(id)])
    end

    ms = maxseg === nothing ? Int(sc.max_segments) : Int(maxseg)
    return Instance(length(node_id), length(links), node_id, arc_from, arc_to, link_id,
                    omega, cap, dem_s, dem_t, vol, P, ms, bud, down)
end
