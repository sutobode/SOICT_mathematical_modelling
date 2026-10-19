using Statistics
function readcsv(file)
    lines = readlines(file)
    head = split(lines[1], ",")
    return [Dict(zip(head, split(l, ","))) for l in lines[2:end] if !isempty(l)]
end
num(r, k) = (v = tryparse(Float64, r[k]); v === nothing ? NaN : v)
avg(v) = (w = filter(!isnan, v); isempty(w) ? NaN : mean(w))
fmt(x; d=4) = isnan(x) ? "--" : string(round(x, digits=d))
function status_summary(rows)
    st = [r["status"] for r in rows]
    k = count(==("Optimal"), st)
    bad = count(r -> !startswith(r["check"], "ok"), rows)
    tag = bad > 0 ? " (check failed $bad)" : ""
    k == length(st) && return "Optimal" * tag
    k == 0 && return join(unique(st), "/") * tag
    return "Optimal $k/$(length(st))" * tag
end
function table(P)
    io = IOBuffer()
    println(io, "\\begin{tabular}{lrrrrrrrlrrr}\n\\hline")
    println(io, "Inst & \$n\$ & \$m\$ & \$|D|\$ & MLU\$_0\$ & MLU & Impr.(\\%) & CPU (s) & Status & Gap & Nodes & Runs \\\\\\hline")
    for i in 1:20
        name = "setA-" * lpad(i, 2, '0')
        f = joinpath(@__DIR__, "..", "results", "$name-P$P.csv")
        isfile(f) || continue
        rows = readcsv(f)
        r1 = rows[1]
        if r1["status"] in ("SKIPPED_TOO_LARGE", "ERROR") && length(rows) == 1
            println(io, "$name & $(r1["n"]) & $(r1["m"]) & $(r1["nD"]) & \\multicolumn{8}{l}{$(replace(r1["status"], "_" => "\\_"))} \\\\")
            continue
        end
        good = filter(r -> startswith(r["check"], "ok"), rows)   # chỉ lấy các lần chạy có nghiệm đã kiểm tra
        g(k) = avg([num(r, k) for r in good])
        gt(k) = avg([num(r, k) for r in rows])
        println(io, join([name, r1["n"], r1["m"], r1["nD"], fmt(num(r1, "mlu_base")), fmt(g("mlu")),
                          fmt(100 * g("improvement"); d=1), fmt(gt("solve_time"); d=1), status_summary(rows),
                          fmt(gt("gap")), fmt(gt("nodes"); d=0), string(length(rows))], " & "), " \\\\")
    end
    println(io, "\\hline\n\\end{tabular}")
    return String(take!(io))
end
for P in (1, 2)
    write(joinpath(@__DIR__, "..", "..", "report", "table_P$P.tex"), table(P))
end
