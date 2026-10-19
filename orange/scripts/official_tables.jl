using Statistics
# Sinh hai bảng kết quả theo đúng yêu cầu của readme (bước 6: t=0, 1800 s; bước 9: t=0,1, 3600 s).
# Cột: số đỉnh, số cung, số demand, giá trị tối ưu hoặc tốt nhất (MLU), CPU time của optimize!, status,
# gap = 1 - LB/UB nếu không tối ưu, số nút B&B; số liệu thời gian, gap, nút là TRUNG BÌNH các lần chạy.
#
# Nguồn của từng dòng:
#   "arc-pc"    : mô hình theo cung của đề (maxSeg = 6) với r theo calculating_r.pdf  -> setA-XX-P{P}-pc.csv
#   "waypoint*" : khi mô hình theo cung không dựng được (SKIPPED_TOO_LARGE): nghiệm tốt nhất của mô hình waypoint
#                 (bài toán hạn chế: một waypoint mỗi demand), lấy từ best_known.csv; status và gap tính theo cận dưới
#                 của bài toán một waypoint (dấu *).
# Chạy: julia orange/scripts/official_tables.jl [pc|ecmp]   (mặc định: pc cho mô hình theo cung)
resdir = joinpath(@__DIR__, "..", "results")
arc_tag = length(ARGS) >= 1 && ARGS[1] == "ecmp" ? "" : "-pc"

function readcsv(file)
    isfile(file) || return Dict{String,String}[]
    lines = filter(!isempty, readlines(file))
    length(lines) < 2 && return Dict{String,String}[]
    head = split(lines[1], ",")
    return [Dict(zip(head, split(l, ","))) for l in lines[2:end] if length(split(l, ",")) == length(head)]
end
num(r, k) = (v = tryparse(Float64, get(r, k, "")); v === nothing ? NaN : v)
avg(v) = (w = filter(!isnan, v); isempty(w) ? NaN : mean(w))
fmt(x; d=5) = isnan(x) ? "--" : string(round(x, digits=d))
fmte(x) = isnan(x) ? "--" : (x == 0 ? "0" : string(round(x, sigdigits=2)))

best = Dict{Tuple{String,Int},Dict{String,String}}()
for r in readcsv(joinpath(resdir, "best_known.csv"))
    best[(r["instance"], parse(Int, r["P"]))] = r
end

# giá trị tốt nhất biết được bằng mọi phương pháp (bảng best_known.csv), để đối chiếu với dòng của mô hình theo cung
bestany(name, P) = haskey(best, (name, P)) ? fmt(parse(Float64, best[(name, P)]["best_mlu"])) : "--"

function wp_file(name, P, source)
    parts = split(source, "-")
    suffix = join(parts[2:end], "-")
    return joinpath(resdir, "$name-wp-P$P" * (isempty(suffix) ? "" : "-" * suffix) * ".csv")
end

for P in (1, 2)
    rows_out = Vector{Vector{String}}()
    for i in 1:20
        name = "setA-" * lpad(i, 2, '0')
        arc = readcsv(joinpath(resdir, "$name-P$P$arc_tag.csv"))
        ok = filter(r -> startswith(get(r, "check", ""), "ok"), arc)
        if !isempty(ok)
            status = all(r -> r["status"] == "Optimal", ok) ? "Optimal" : "Not Optimal"
            gap = status == "Optimal" ? "--" : fmte(avg([num(r, "gap") for r in ok]))
            push!(rows_out, [name, arc[1]["n"], arc[1]["m"], arc[1]["nD"], fmt(minimum(num(r, "mlu") for r in ok)),
                             fmt(avg([num(r, "solve_time") for r in ok]); d=1), status, gap,
                             fmt(avg([num(r, "nodes") for r in ok]); d=0), string(length(ok)), "arc-pc", bestany(name, P)])
            continue
        end
        b = get(best, (name, P), nothing)
        if b === nothing
            n = isempty(arc) ? "--" : arc[1]["n"]
            push!(rows_out, [name, n, isempty(arc) ? "--" : arc[1]["m"], isempty(arc) ? "--" : arc[1]["nD"], "--", "--", "no result", "--", "--", "0", "--", bestany(name, P)])
            continue
        end
        src = b["source"]
        srows = filter(r -> startswith(get(r, "check", ""), "ok"), readcsv(wp_file(name, P, src)))
        gap1 = parse(Float64, b["gap_1wp"])
        status = isnan(gap1) ? "Not Optimal*" : (gap1 < 1e-5 ? "Optimal*" : "Not Optimal*")
        info = isempty(srows) ? Dict{String,String}() : srows[1]
        push!(rows_out, [name, get(info, "n", "--"), get(info, "m", "--"), get(info, "nD", "--"),
                         fmt(parse(Float64, b["best_mlu"])), fmt(avg([num(r, "solve_time") for r in srows]); d=1), status,
                         status == "Optimal*" ? "--" : fmte(gap1), fmt(avg([num(r, "nodes") for r in srows]); d=0),
                         string(length(srows)), src, bestany(name, P)])
    end
    head = ["Instance", "Vertices", "Links", "Demands", "Best objective (MLU)", "CPU time (s)", "Status", "Gap", "B&B nodes", "Runs", "Model", "Best known (any method)"]
    title = P == 1 ? "Table 1 -- time period 0 only, limit 1800 s (step 6)" : "Table 2 -- time periods 0 and 1 with budget, limit 3600 s (step 9)"
    open(joinpath(resdir, "table_official_P$P.md"), "w") do io
        println(io, "# $title\n")
        println(io, "| ", join(head, " | "), " |\n|", join(fill("---", length(head)), "|"), "|")
        for r in rows_out
            println(io, "| ", join(r, " | "), " |")
        end
        println(io, "\nModel `arc-pc`: arc-based MILP of the statement, split coefficients r from calculating_r.pdf. Rows marked * come from the waypoint model " *
                    "(restricted problem: at most one waypoint per demand) because the arc-based model does not fit in memory; their status and gap refer to that restricted problem. " *
                    "Time, gap and nodes are averages over the runs listed in column Runs. Last column: best MLU found by any method (waypoint model, column generation, LNS), for comparison with the arc-model row.")
    end
    open(joinpath(resdir, "table_official_P$P.csv"), "w") do io
        println(io, join(head, ","))
        for r in rows_out
            println(io, join(replace.(r, "," => ";"), ","))
        end
    end
    println("wrote table_official_P$P ($(length(rows_out)) rows)")
end
