using Orange
# julia --project=orange orange/scripts/run_wp.jl <P> <tlimit> [first] [last] [max_binaries] [cg] [pc] [lns] [lns_seconds]
# tham số cuối "cg": chọn ứng viên bằng sinh cột (kết quả ghi với hậu tố -cg)
P = parse(Int, ARGS[1])
tlimit = parse(Float64, ARGS[2])
first_i = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 1
last_i = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 20
maxb = length(ARGS) >= 5 ? parse(Int, ARGS[5]) : 1_500_000
cg = length(ARGS) >= 6 && ARGS[6] == "cg"
lns_seconds = length(ARGS) >= 9 ? parse(Float64, ARGS[9]) : 300.0
lns = length(ARGS) >= 8 && ARGS[8] == "lns"      # tinh chỉnh LNS sau MILP (300 s mỗi instance), hậu tố -lns
pc = length(ARGS) >= 7 && ARGS[7] == "pc"      # r theo công thức đếm đường của calculating_r.pdf (hậu tố -pc)
outdir = joinpath(@__DIR__, "..", "results")
for i in first_i:last_i
    name = "setA-" * lpad(i, 2, '0')
    prefix = joinpath(@__DIR__, "..", "..", "project", "setA", name)
    println("== $name P=$P cg=$cg pc=$pc  free RAM ", round(Sys.free_memory() / 2^30, digits=1), " GiB"); flush(stdout)
    run_wp_instance(prefix, name, P, tlimit; outdir=outdir, max_binaries=maxb,
                    use_colgen=cg, use_lns=lns, lns_time=lns_seconds, r_mode=pc ? :pathcount : :ecmp,
                    tag=(cg ? "-cg" : "") * (pc ? "-pc" : "") * (lns ? "-lns" : ""))
end
