using Statistics
# Tổng hợp nghiệm tốt nhất theo từng instance và P từ ba nguồn trong orange/results:
#   arc : setA-XX-P{P}.csv        (mô hình theo cung của đề; Optimal => tối ưu của bài toán gốc)
#   wp  : setA-XX-wp-P{P}.csv     (mô hình waypoint, K ứng viên theo độ vòng)
#   cg  : setA-XX-wp-P{P}-cg.csv  (mô hình waypoint, ứng viên do sinh cột chọn)
# Cột lb: cận dưới đã biết trên MLU tối ưu của bài toán **một waypoint** (cg_lp với P=1; hoặc chính giá trị tối ưu
# khi mô hình waypoint đầy đủ giải xong), hoặc của bài toán gốc nếu mô hình theo cung Optimal.
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

open(joinpath(resdir, "best_known.csv"), "w") do io
    println(io, "instance,P,best_mlu,source,mlu_base,improvement,lb,gap_to_lb,exact_for")
    for i in 1:20, P in (1, 2)
        name = "setA-" * lpad(i, 2, '0')
        cand = Tuple{Float64,String}[]
        base, lb, exact = NaN, NaN, ""
        arc = readcsv(joinpath(resdir, "$name-P$P.csv"))
        for r in filter(good, arc)
            push!(cand, (num(r, "mlu"), "arc"))
            isnan(base) && (base = num(r, "mlu_base"))
        end
        if any(r -> get(r, "status", "") == "Optimal" && good(r), arc)
            lb = minimum(num(r, "mlu") for r in arc if good(r)); exact = "maxSeg=6"
        end
        for (tag, suffix) in (("wp", ""), ("cg", "-cg"))
            rows = readcsv(joinpath(resdir, "$name-wp-P$P$suffix.csv"))
            for r in filter(good, rows)
                push!(cand, (num(r, "mlu"), tag))
                isnan(base) && (base = num(r, "mlu_base"))
                if get(r, "status", "") == "Optimal" && tag == "wp" && isnan(lb)
                    lb = num(r, "mlu"); exact = "1 waypoint"
                end
                if tag == "cg" && P == 1 && !isnan(num(r, "cg_lp"))
                    (isnan(lb) || num(r, "cg_lp") > lb) && (lb = num(r, "cg_lp"); exact = "1 waypoint (LP)")
                end
            end
        end
        isempty(cand) && continue
        best, src = minimum(cand)
        gap = isnan(lb) ? NaN : max(0.0, 1.0 - lb / best)
        println(io, join([name, P, best, src, base, 1 - best / base, lb, gap, exact], ","))
    end
end
println("wrote ", joinpath(resdir, "best_known.csv"))
