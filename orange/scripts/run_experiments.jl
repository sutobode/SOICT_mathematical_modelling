using Orange
# julia --project=orange orange/scripts/run_experiments.jl <P> <tlimit> [first] [last] [pc]
# tham số cuối "pc": hệ số tách r theo công thức đếm đường của calculating_r.pdf (kết quả có hậu tố -pc);
# mặc định r theo ECMP từng chặng (đúng định nghĩa của đề).
P = parse(Int, ARGS[1])
tlimit = parse(Float64, ARGS[2])
first_i = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 1
last_i = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 20
pc = length(ARGS) >= 5 && ARGS[5] == "pc"
outdir = joinpath(@__DIR__, "..", "results")
for i in first_i:last_i
    name = "setA-" * lpad(i, 2, '0')
    prefix = joinpath(@__DIR__, "..", "..", "project", "setA", name)
    println("== $name P=$P pc=$pc  ", time()); flush(stdout)
    run_instance(prefix, name, P, tlimit; outdir=outdir, r_mode=pc ? :pathcount : :ecmp, tag=pc ? "-pc" : "")
end
