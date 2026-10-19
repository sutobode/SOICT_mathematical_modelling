using Orange
# julia --project=orange orange/scripts/run_experiments.jl <P> <tlimit> [first] [last] [pc|ecmp] [first_run] [runs] [tag_suffix]
# tham số cuối "pc": hệ số tách r theo công thức đếm đường của calculating_r.pdf (kết quả có hậu tố -pc);
# mặc định r theo ECMP từng chặng (đúng định nghĩa của đề).
P = parse(Int, ARGS[1])
tlimit = parse(Float64, ARGS[2])
first_i = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 1
last_i = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 20
pc = length(ARGS) >= 5 && ARGS[5] == "pc"
first_run = length(ARGS) >= 6 ? parse(Int, ARGS[6]) : 1       # first_run > 1: chạy bổ sung các lần first_run..runs (đủ 10 lần)
nruns = length(ARGS) >= 7 ? parse(Int, ARGS[7]) : 10
suffix = length(ARGS) >= 8 ? ARGS[8] : ""                    # hậu tố tên file để không ghi chồng lên file đang dùng, ví dụ -r4-10
outdir = joinpath(@__DIR__, "..", "results")
for i in first_i:last_i
    name = "setA-" * lpad(i, 2, '0')
    prefix = joinpath(@__DIR__, "..", "..", "project", "setA", name)
    println("== $name P=$P pc=$pc  ", time()); flush(stdout)
    run_instance(prefix, name, P, tlimit; outdir=outdir, r_mode=pc ? :pathcount : :ecmp, tag=(pc ? "-pc" : "") * suffix,
                 runs=nruns, first_run=first_run, force_runs=first_run > 1)
end
