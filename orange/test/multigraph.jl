# Kiểm tra: dữ liệu SetA của thầy có thật sự là ĐA ĐỒ THỊ (multigraph) hay không?
#
# Nhiều file `*-net.json` khai báo `"multigraph": true`, nhưng cờ đó chỉ là thuộc tính của định dạng NetworkX, không đảm bảo
# có cung song song. Test này đọc JSON thô (không dùng `read_instance`, để không phụ thuộc vào chính mã cần kiểm tra) và kiểm:
#   * không có cung song song: mỗi cặp có thứ tự (from, to) xuất hiện đúng một lần;
#   * không có khuyên (from == to);
#   * id nút và id cung (link) là duy nhất, mọi đầu mút đều là nút có thật;
#   * mọi id cung bị tắt trong `scenario.json` đều tồn tại (quan trọng: nếu có cung song song thì chỉ biết cung nào qua id);
#   * `read_instance` đọc được và giữ nguyên mọi cung (m = số link).
# Có kèm "đối chứng dương": một mạng tổng hợp có cung song song PHẢI bị cùng bộ kiểm tra này phát hiện (để chứng minh test
# có khả năng thất bại). Đồng thời in bảng tóm tắt 20 instance.
using Test, Orange, JSON3

const SETA_DIR = joinpath(@__DIR__, "..", "..", "project", "setA")

"Nhóm các link có cùng cặp có thứ tự (from, to); trả về chỉ những nhóm có từ 2 link trở lên."
function parallel_arc_groups(links)
    groups = Dict{Tuple{Int,Int},Vector{Int}}()
    for l in links
        push!(get!(groups, (Int(l["from"]), Int(l["to"])), Int[]), Int(l.id))
    end
    return Dict(k => v for (k, v) in groups if length(v) > 1)
end

self_loops(links) = [Int(l.id) for l in links if Int(l["from"]) == Int(l["to"])]

"Số cặp nút có hai cung ngược chiều (a→b và b→a): hợp lệ trong đồ thị có hướng, KHÔNG phải cung song song."
function antiparallel_pairs(links)
    s = Set((Int(l["from"]), Int(l["to"])) for l in links)
    return count(((a, b),) -> a < b && (b, a) in s, collect(s))
end

@testset "đối chứng dương: mạng có cung song song bị phát hiện" begin
    net = JSON3.read("""{"directed": true, "multigraph": true, "graph": {},
        "nodes": [{"id": 0, "name": "a"}, {"id": 1, "name": "b"}, {"id": 2, "name": "c"}],
        "links": [{"id": 0, "from": 0, "to": 1, "metric": 1, "capacity": 1},
                  {"id": 1, "from": 0, "to": 1, "metric": 2, "capacity": 1},
                  {"id": 2, "from": 1, "to": 0, "metric": 1, "capacity": 1},
                  {"id": 3, "from": 2, "to": 2, "metric": 1, "capacity": 1}]}""")
    groups = parallel_arc_groups(net.links)
    @test groups == Dict((0, 1) => [0, 1])           # hai cung 0→1 song song
    @test (1, 0) ∉ keys(groups)                        # 1→0 chỉ có một cung (ngược chiều, không song song)
    @test self_loops(net.links) == [3]                 # khuyên 2→2
    @test antiparallel_pairs(net.links) == 1           # cặp 0→1 và 1→0
    # và mạng không có cung song song thì không bị báo nhầm
    clean = JSON3.read("""{"links": [{"id": 0, "from": 0, "to": 1}, {"id": 1, "from": 1, "to": 0}, {"id": 2, "from": 1, "to": 2}]}""")
    @test isempty(parallel_arc_groups(clean.links))
    @test isempty(self_loops(clean.links))
end

declared = Bool[]
rows = NTuple{8,String}[]

@testset "SetA: không có cung song song / khuyên (cả khi file khai báo multigraph=true)" begin
    for i in 1:20
        name = "setA-" * lpad(i, 2, '0')
        prefix = joinpath(SETA_DIR, name)
        net = JSON3.read(read(prefix * "-net.json", String))
        sc = JSON3.read(read(prefix * "-scenario.json", String))
        links = net.links
        node_ids = [Int(x.id) for x in net.nodes]
        link_ids = [Int(l.id) for l in links]
        flag = Bool(get(net, :multigraph, false))
        push!(declared, flag)

        @test Bool(get(net, :directed, false))                                   # đồ thị có hướng
        @test allunique(node_ids)
        @test allunique(link_ids)
        @test all(Int(l["from"]) in node_ids && Int(l["to"]) in node_ids for l in links)
        @test isempty(self_loops(links))
        par = parallel_arc_groups(links)
        @test isempty(par)                                                       # KHÔNG có cung song song
        # id cung bị tắt trong kịch bản phải tồn tại
        for iv in sc.interventions, id in iv.links
            @test Int(id) in link_ids
        end
        # mã đọc dữ liệu giữ nguyên mọi cung
        inst = read_instance(prefix)
        @test inst.m == length(links)
        @test inst.n == length(net.nodes)

        push!(rows, (name, string(flag), string(length(node_ids)), string(length(links)),
                     string(length(unique((Int(l["from"]), Int(l["to"])) for l in links))),
                     string(length(par)), string(length(self_loops(links))),
                     string(antiparallel_pairs(links))))
    end
end

# bảng tóm tắt (in ra khi chạy test)
println()
println(rpad("instance", 9), rpad("khai báo multigraph", 21), rpad("nút", 6), rpad("link", 7), rpad("cặp (from,to) khác nhau", 25),
        rpad("nhóm song song", 16), rpad("khuyên", 8), "cặp ngược chiều")
for r in rows
    println(rpad(r[1], 9), rpad(r[2], 21), rpad(r[3], 6), rpad(r[4], 7), rpad(r[5], 25), rpad(r[6], 16), rpad(r[7], 8), r[8])
end
println("Số instance khai báo multigraph=true: ", count(declared), "/20; số instance thật sự có cung song song: ",
        count(r -> r[6] != "0", rows), "/20")
