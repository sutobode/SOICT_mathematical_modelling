const RTOL = 1e-9
isclose(a, b) = isapprox(a, b; rtol=RTOL, atol=1e-12)

struct Routing
    D::Matrix{Float64}          # D[u,v]: khoảng cách ngắn nhất trong G_p
    S::Matrix{Float64}          # S[u,v]: số đường ngắn nhất (cho :pathcount)
    out::Vector{Vector{Int}}    # out[x]: cung ra còn hoạt động của x
end

function routing(inst::Instance, p::Int)
    n = inst.n
    active = [a for a in 1:inst.m if !(a in inst.down[p])]
    g = SimpleDiGraph(n)
    out = [Int[] for _ in 1:n]
    for a in active
        add_edge!(g, inst.arc_from[a], inst.arc_to[a])
        push!(out[inst.arc_from[a]], a)
    end
    W = sparse(inst.arc_from[active], inst.arc_to[active], inst.omega[active], n, n)
    D = Matrix{Float64}(undef, n, n)
    for s in 1:n
        D[s, :] = dijkstra_shortest_paths(g, s, W).dists
    end
    # đếm đường ngắn nhất theo thứ tự khoảng cách, so sánh có dung sai
    S = zeros(n, n)
    for s in 1:n
        S[s, s] = 1.0
        for x in sort([x for x in 1:n if isfinite(D[s, x])], by=x -> D[s, x]), a in out[x]
            y = inst.arc_to[a]
            isclose(D[s, x] + inst.omega[a], D[s, y]) && (S[s, y] += S[s, x])
        end
    end
    return Routing(D, S, out)
end

"Luồng đơn vị từ u đến v, chia đều tại mỗi nút cho các cung ra thuộc FG(u,v)."
function ecmp_split(inst::Instance, R::Routing, u::Int, v::Int)
    res = Dict{Int,Float64}()
    D = R.D
    (u == v || !isfinite(D[u, v])) && return res
    nodes = [x for x in 1:inst.n if isfinite(D[u, x]) && isfinite(D[x, v]) &&
             isclose(D[u, x] + D[x, v], D[u, v])]
    sort!(nodes, by=x -> D[u, x])
    flow = zeros(inst.n)
    flow[u] = 1.0
    for x in nodes
        x == v && continue
        outs = [a for a in R.out[x] if isfinite(D[inst.arc_to[a], v]) &&
                isclose(D[u, x] + inst.omega[a] + D[inst.arc_to[a], v], D[u, v])]
        isempty(outs) && continue
        share = flow[x] / length(outs)
        for a in outs
            res[a] = get(res, a, 0.0) + share
            flow[inst.arc_to[a]] += share
        end
    end
    return res
end

"Tỷ lệ số đường ngắn nhất đi qua cung (công thức của calculating_r.pdf)."
function pathcount_split(inst::Instance, R::Routing, u::Int, v::Int)
    res = Dict{Int,Float64}()
    D, S = R.D, R.S
    (u == v || !isfinite(D[u, v])) && return res
    for x in 1:inst.n, a in R.out[x]
        y = inst.arc_to[a]
        (isfinite(D[u, x]) && isfinite(D[y, v])) || continue
        isclose(D[u, x] + inst.omega[a] + D[y, v], D[u, v]) || continue
        res[a] = S[u, x] * S[y, v] / S[u, v]
    end
    return res
end

function build_r(inst::Instance, p::Int; mode::Symbol=:ecmp)
    split = mode === :ecmp ? ecmp_split :
            mode === :pathcount ? pathcount_split : error("unknown r mode $mode")
    R = routing(inst, p)
    r = Dict{Tuple{Int,Int},Vector{Pair{Int,Float64}}}()
    for i in 1:inst.n, j in 1:inst.n
        i == j && continue
        f = split(inst, R, i, j)
        isempty(f) || (r[(i, j)] = collect(f))
    end
    return r
end
