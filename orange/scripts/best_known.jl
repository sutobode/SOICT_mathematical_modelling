# Tổng hợp nghiệm tốt nhất theo từng instance và P từ ba nguồn trong orange/results:
#   arc : setA-XX-P{P}.csv        (mô hình theo cung của đề, maxSeg = 6)
#   wp  : setA-XX-wp-P{P}.csv     (mô hình waypoint, K ứng viên theo độ vòng; K = n-2 là mô hình đầy đủ)
#   wp-cg, wp-cg-lns, ...: setA-XX-wp-P{P}-cg[-pc|-lns].csv (sinh cột, có thể kèm LNS; -pc: r theo calculating_r.pdf)
# Mọi nghiệm đều khả thi cho bài toán gốc (một waypoint <= maxSeg - 1), nên best_mlu là cận trên hợp lệ của tối ưu gốc.
#
# Cận dưới trên MLU z (đã trừ phần phạt eps*sum(x) của hàm mục tiêu; eps = 1e-7/|D|):
#   lb_orig : cận dưới của bài toán GỐC (maxSeg = 6): cận đối ngẫu `bound` của mô hình theo cung trừ 1e-7*P*maxSeg;
#             hoặc chính MLU nếu mô hình theo cung Optimal.
#   lb_1wp  : cận dưới của bài toán MỘT WAYPOINT: `bound` của mô hình waypoint đầy đủ (K = n-2) trừ 1e-7*P, hoặc
#             giá trị LP khi sinh cột hội tụ (chỉ P = 1) trừ 1e-7*P.
# Chạy: julia orange/scripts/best_known.jl  ->  orange/results/best_known.csv
resdir = joinpath(@__DIR__, "..", "results")

function readcsv(file)
    isfile(file) || return Dict{String,String}[]
    lines = filter(!isempty, readlines(file))
    length(lines) < 2 && return Dict{String,String}[]
    head = split(lines[1], ",")
    return [Dict(zip(head, split(l, ","))) for l in lines[2:end] if length(split(l, ",")) == length(head)]
end
num(r, k) = (v = tryparse(Float64, get(r, k, "")); v === nothing ? NaN : v)
good(r) = startswith(get(r, "check", ""), "ok") && !isnan(num(r, "mlu"))
maxnan(a, b) = isnan(a) ? b : (isnan(b) ? a : max(a, b))
gap(best, lb) = isnan(lb) ? NaN : max(0.0, 1.0 - lb / best)

open(joinpath(resdir, "best_known.csv"), "w") do io
    println(io, "instance,P,best_mlu,source,mlu_base,improvement,lb_orig,gap_orig,lb_1wp,gap_1wp")
    for i in 1:20, P in (1, 2)
        name = "setA-" * lpad(i, 2, '0')
        cand = Tuple{Float64,String}[]
        base, lb_orig, lb_1wp = NaN, NaN, NaN
        arc = readcsv(joinpath(resdir, "$name-P$P.csv"))
        for r in arc
            if good(r)
                push!(cand, (num(r, "mlu"), "arc"))
                isnan(base) && (base = num(r, "mlu_base"))
            end
            b = num(r, "bound")
            isnan(b) || (lb_orig = maxnan(lb_orig, b - 1e-7 * P * 6))
            get(r, "status", "") == "Optimal" && good(r) && (lb_orig = maxnan(lb_orig, num(r, "mlu")))
        end
        # mọi file waypoint của (instance, P): hậu tố "", "-cg", "-cg-lns", "-cg-pc", ... ("-pc": r theo calculating_r.pdf)
        for f in sort(filter(f -> startswith(basename(f), "$name-wp-P$P") && endswith(f, ".csv") && !endswith(f, "-loads.csv"),
                             readdir(resdir; join=true)))
            suffix = replace(basename(f), "$name-wp-P$P" => "", ".csv" => "")
            tag = isempty(suffix) ? "wp" : "wp" * suffix
            for r in readcsv(f)
                if good(r)
                    push!(cand, (num(r, "mlu"), tag))
                    isnan(base) && (base = num(r, "mlu_base"))
                end
                n = num(r, "n")
                if isempty(suffix) && num(r, "K") == n - 2 && !isnan(num(r, "bound"))
                    lb_1wp = maxnan(lb_1wp, num(r, "bound") - 1e-7 * P)         # mô hình đầy đủ: bound hợp lệ
                end
                if occursin("cg", suffix) && P == 1 && !isnan(num(r, "cg_lp"))
                    lb_1wp = maxnan(lb_1wp, num(r, "cg_lp") - 1e-7 * P)
                end
            end
        end
        isempty(cand) && continue
        best, src = minimum(cand)
        # cận dưới của bài toán một waypoint cũng là cận dưới của bài toán gốc? KHÔNG (gốc cho phép nhiều waypoint hơn),
        # nên lb_orig chỉ lấy từ mô hình theo cung.
        println(io, join([name, P, best, src, base, 1 - best / base, lb_orig, gap(best, lb_orig), lb_1wp, gap(best, lb_1wp)], ","))
    end
end
println("wrote ", joinpath(resdir, "best_known.csv"))
