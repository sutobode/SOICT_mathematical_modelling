segs(seq) = zip(seq, seq[2:end])

"""
Tìm kiếm cục bộ: lặp lại việc đổi waypoint (không waypoint hoặc đúng 1 waypoint) của một demand
đi qua cung tải lớn nhất, nhận nếu MLU giảm và ngân sách không bị vi phạm.
"""
function local_search(inst::Instance, rs, P::Int; time_limit=600.0, cand_per_move=50, seed=1)
    rng = MersenneTwister(seed)
    nD = length(inst.dem_s)
    paths = direct_paths(inst, P)
    flow = [zeros(inst.m) for _ in 1:P]
    function apply!(d, p, seq, sgn)
        for (u, v) in segs(seq), (a, fr) in rs[p][(u, v)]
            flow[p][a] += sgn * fr * inst.vol[d, p]
        end
    end
    for d in 1:nD, p in 1:P
        apply!(d, p, paths[(d, p)], 1.0)
    end
    current() = maximum(maximum(flow[p] ./ inst.cap) for p in 1:P)
    used = zeros(P)                                        # thay đổi đã dùng giữa p-1 và p
    t0 = time()
    best = current()
    while time() - t0 < time_limit
        # cung tải lớn nhất
        bp, ba = 1, 1
        for p in 1:P, a in 1:inst.m
            flow[p][a] / inst.cap[a] > flow[bp][ba] / inst.cap[ba] && ((bp, ba) = (p, a))
        end
        users = [d for d in 1:nD if inst.vol[d, bp] > 0 &&
                 any(a == ba for (u, v) in segs(paths[(d, bp)]) for (a, _) in rs[bp][(u, v)])]
        improved = false
        for d in shuffle(rng, users)
            s, t = inst.dem_s[d], inst.dem_t[d]
            cands = shuffle(rng, [w for w in 0:inst.n if w == 0 || (w != s && w != t)])
            for w in cands[1:min(end, cand_per_move)]
                new = w == 0 ? [s, t] : [s, w, t]
                old = paths[(d, bp)]
                new == old && continue
                all(seg -> haskey(rs[bp], seg), segs(new)) || continue
                # ngân sách: ảnh hưởng tới thời kỳ bp (so với bp-1) và bp+1 (so với bp)
                delta = Dict{Int,Float64}()
                bp >= 2 && (delta[bp] = changes(paths[(d, bp-1)], new) - changes(paths[(d, bp-1)], old))
                bp < P && (delta[bp+1] = changes(new, paths[(d, bp+1)]) - changes(old, paths[(d, bp+1)]))
                all(q -> used[q] + delta[q] <= inst.budget[q], keys(delta)) || continue
                apply!(d, bp, old, -1.0); apply!(d, bp, new, 1.0)
                val = current()
                if val < best - 1e-12
                    paths[(d, bp)] = new
                    for (q, dq) in delta; used[q] += dq; end
                    best, improved = val, true
                    break
                end
                apply!(d, bp, new, -1.0); apply!(d, bp, old, 1.0)
            end
            improved && break
        end
        improved || break                                  # cực tiểu địa phương
    end
    return paths, max_utilization(inst, rs, paths, P)
end
