segs(seq) = zip(seq, seq[2:end])

"""
Tìm kiếm cục bộ: lặp lại việc đổi waypoint (không waypoint hoặc đúng 1 waypoint) của một demand
đi qua cung tải lớn nhất, nhận nếu MLU giảm và ngân sách không bị vi phạm. Mỗi bước thử đổi
riêng thời kỳ tải lớn nhất, rồi thử đổi cùng lúc mọi thời kỳ.
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
        # đổi đường của d thành new tại các thời kỳ ps; nhận nếu MLU giảm và ngân sách không bị vi phạm
        function try_move!(d, ps, new)
            any(p -> paths[(d, p)] != new, ps) || return false
            all(p -> all(seg -> haskey(rs[p], seg), segs(new)), ps) || return false
            trial(p) = p in ps ? new : paths[(d, p)]
            delta = Dict(q => changes(trial(q-1), trial(q)) - changes(paths[(d, q-1)], paths[(d, q)])
                         for q in 2:P if q in ps || q - 1 in ps)
            all(q -> used[q] + delta[q] <= inst.budget[q], keys(delta)) || return false
            for p in ps; apply!(d, p, paths[(d, p)], -1.0); apply!(d, p, new, 1.0); end
            val = current()
            if val < best - 1e-12
                for p in ps; paths[(d, p)] = new; end
                for (q, dq) in delta; used[q] += dq; end
                best = val
                return true
            end
            for p in ps; apply!(d, p, new, -1.0); apply!(d, p, paths[(d, p)], 1.0); end
            return false
        end
        improved = false
        for d in shuffle(rng, users)
            s, t = inst.dem_s[d], inst.dem_t[d]
            cands = shuffle(rng, [w for w in 0:inst.n if w == 0 || (w != s && w != t)])
            for w in cands[1:min(end, cand_per_move)]
                new = w == 0 ? [s, t] : [s, w, t]
                # đổi riêng thời kỳ bp; nếu không được thì đổi cùng lúc mọi thời kỳ (không tốn ngân sách
                # khi đường đang giống nhau, nên vẫn đi được khi ngân sách < 3)
                improved = try_move!(d, (bp,), new) || (P > 1 && try_move!(d, 1:P, new))
                improved && break
            end
            improved && break
        end
        improved || break                                  # cực tiểu địa phương
    end
    return paths, max_utilization(inst, rs, paths, P)
end
