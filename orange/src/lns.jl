"""
Tìm kiếm lân cận lớn (LNS) trên mô hình waypoint: mỗi vòng giữ nguyên lựa chọn của phần lớn demand và chỉ giải lại
MILP cho một nhóm `frac·|D|` demand, ưu tiên các demand đi qua cung nghẽn nhất (cung có tải >= 98% MLU ở kỳ xấu nhất),
bổ sung bằng demand ngẫu nhiên. Nhận nghiệm mới nếu MLU giảm. Trả về (paths, mlu) không bao giờ tệ hơn `start_paths`.
"""
function lns(inst::Instance, rs, P::Int, optimizer; K::Int=20, cands=nothing, start_paths,
             iters::Int=20, frac::Float64=0.3, tlimit_iter::Float64=30.0, total_limit::Float64=Inf, seed::Int=1)
    rng = MersenneTwister(seed)
    nD = length(inst.dem_s)
    C = cands === nothing ? candidates(inst, rs, K) : cands
    cur = start_paths
    best = max_utilization(inst, rs, cur, P)
    nfree = clamp(ceil(Int, frac * nD), 1, nD)
    t0 = time()
    for it in 1:iters
        time() - t0 > total_limit && break
        u = [utilization(inst, rs, cur, p) for p in 1:P]
        wp = argmax([maximum(u[p]) for p in 1:P])
        hot = Set(a for a in 1:inst.m if u[wp][a] >= 0.98 * maximum(u[wp]))
        users = [d for d in 1:nD if inst.vol[d, wp] > 0 &&
                 any(a in hot for (x, y) in zip(cur[(d, wp)], cur[(d, wp)][2:end]) for (a, _) in rs[wp][(x, y)])]
        free = shuffle(rng, users)[1:min(nfree, length(users))]
        if length(free) < nfree
            others = shuffle(rng, setdiff(1:nD, free))
            append!(free, others[1:min(nfree - length(free), length(others))])
        end
        model, y, W = build_wp_model(inst, rs, P, optimizer; cands=C, start_paths=cur,
                                     tlimit=tlimit_iter, freeze=setdiff(1:nD, free))
        optimize!(model)
        has_values(model) || continue
        cand = extract_wp_paths(inst, y, W, P)
        m = max_utilization(inst, rs, cand, P)
        if m < best - 1e-12
            cur, best = cand, m
        end
    end
    return cur, best
end
