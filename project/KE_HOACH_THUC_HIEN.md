# Orange T-ASR — Kế hoạch thực hiện

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cài đặt mô hình MILP T-ASR bằng Julia/JuMP, chạy thực nghiệm trên SetA (t=0 với 1800 s; t=0,1 với 3600 s) và viết báo cáo ≤ 10 trang, nộp trước **Chủ nhật 25/10/2026**.

**Architecture:** Một package Julia `Orange` gồm các file nhỏ: đọc dữ liệu (`io.jl`) → tính hệ số tách $r$ theo ECMP từng chặng hoặc theo đếm đường (`ecmp.jl`) → dựng mô hình JuMP (`model.jl`) → kiểm tra nghiệm độc lập với solver (`verify.jl`) → chạy thực nghiệm và ghi CSV (`experiment.jl`). Mô hình được kiểm chứng trên ví dụ toy của đề và bằng vét cạn trước khi chạy SetA. Các phần mở rộng (heuristic, độ nhạy ngân sách, so sánh cách tính $r$) là task tùy chọn ở cuối.

**Tech Stack:** Julia 1.13.1 (đã cài trên máy), JuMP, HiGHS (mã mở), Graphs.jl, SparseArrays, JSON3, Random, Statistics, Test. Báo cáo: LaTeX + pgfplots.

**Spec:** [`BAI_TOAN_FINAL.md`](BAI_TOAN_FINAL.md) (phân tích đã kiểm chứng), cùng [`readme`](readme) và `Challenge_Orange_ROADEF_2026_Subject.pdf`.

**Cách theo dõi:** đánh dấu `- [x]` vào từng bước khi hoàn thành. Bảng tiến độ ở mục "Lịch thực hiện" cập nhật cột "Trạng thái".

### Tiến độ (cập nhật 19/10, nhánh `feature/tasr`)

| Task | Nội dung | Trạng thái |
|---|---|---|
| 0 | Khởi tạo package, dữ liệu toy | ✅ xong (thầy không trả lời nên các câu hỏi đã được tự quyết, xem "Nhật ký quyết định") |
| 1 | Đọc dữ liệu | ✅ xong |
| 2 | Hệ số tách $r$ (ECMP + đếm đường) | ✅ xong, khớp Bảng 2 của đề |
| 3 | Mô hình JuMP | ✅ xong, khớp vét cạn trên toy |
| 4 | Kiểm tra nghiệm, `srpaths` | ✅ xong |
| 5 | Toy $t=0,1$, setA-01 | ✅ xong; ngưỡng `max_vars` giữ $3\cdot10^6$ |
| 6 | Runner thực nghiệm | ✅ xong |
| 7 | Chạy thực nghiệm đầy đủ | 🔄 **đang chạy nền** ($t=0$ rồi $t=0,1$), log: `orange/results/log-P{1,2}.txt` |
| 8 | Bảng và báo cáo | 🔄 `make_tables.jl` và phần 1–3.2 của `report.tex` xong; còn kết quả và nhận xét |
| 9, 10 | Độ nhạy ngân sách, so sánh $r$ | ⏳ script đã viết, chạy sau Task 7 |
| 11 | Heuristic | ✅ xong (script `run_heuristic.jl`, chạy cả 20 instance sau Task 7) |
| 12 | Lexicographic hai bước | ✅ xong |
| Review | Review toàn nhánh (reviewer độc lập) | ✅ 2 lỗi Important đã sửa; Minor ghi trong sổ |

Thay đổi so với kế hoạch gốc: MILP được khởi tạo bằng nghiệm heuristic; chu trình rời bị chặn bằng ràng buộc bậc (và MTZ khi cần); `mip_rel_gap=1e-6`; $\varepsilon=10^{-7}/|D|$.

---

## Global Constraints

- Hạn nộp **Chủ nhật 25/10/2026**. Báo cáo **tối đa 10 trang**: Giới thiệu; Mô hình toán (Data, Biến, Mục tiêu, Ràng buộc, giải thích chi tiết); Thực nghiệm (mô tả instance, môi trường chạy, bảng kết quả).
- Giới hạn solver: **1800 s** cho chỉ $t=0$ (không có ràng buộc ngân sách (4)); **3600 s** cho $t=0$ và $t=1$ (có ngân sách).
- Bảng kết quả bắt buộc: số đỉnh, số cung, số demand, giá trị tối ưu hoặc tốt nhất, CPU time của **riêng `optimize!`**, status (Optimal / Not Optimal / Infeasible), gap $=1-\mathrm{LB}/\mathrm{UB}$ nếu Not Optimal, số nút B&B. Yêu cầu: **trung bình trên 10 lần chạy**.
- Mặc định $r$ tính theo **ECMP từng chặng**; phải hỗ trợ cả cách **đếm đường** của `calculating_r.pdf` (tham số `mode`), chờ thầy xác nhận.
- $r(\cdot,\cdot,\cdot,t)$ tính trên $G_t$ (đã loại $q(t)$). Intervention tham chiếu cung theo `id` của link.
- So sánh khoảng cách dùng dung sai `rtol=1e-9` (metric thực ở instance 05, 08, 12, 14).
- Không tin cờ `multigraph` (10/20 instance khai `true` nhưng không có cung song song). Tự đọc JSON, tự kiểm tra cung song song.
- Mô hình luôn khả thi. **Infeasible là dấu hiệu lỗi.**
- HiGHS chạy **1 luồng** (`threads=1`) để thời gian thực của `optimize!` xấp xỉ CPU time. Không chạy song song nhiều tiến trình khi đo các bảng chính.

## Review Focus

1. **Chu trình rời trong nghiệm của solver:** ràng buộc (1) cho phép "đường + chu trình". Đường trích ra phải đúng từ $s$ đến $\tau$ và MLU tính lại phải $\le z$. Test: Task 3 (`extract_paths ignores cycles`).
2. **Đoạn không có đường trong $G_t$:** phải bị cấm ($x=0$), nếu không mô hình đi "tắt" miễn phí. Test: Task 3 (`unreachable segments are forbidden`).
3. **Metric thực và hòa khoảng cách:** `0.1+0.2` và `0.15+0.15` phải được coi là bằng nhau. Test: Task 2 (`ecmp float ties`).
4. **Ngân sách 0 hoặc 1:** với $\beta=0$ đường phải giống hệt nhau ở hai thời kỳ. Test: Task 4 (`budget 0 forces identical routing`).
5. **Một instance lỗi làm dừng cả lô chạy qua đêm:** lỗi phải được ghi vào CSV và lô chạy tiếp. Test: Task 6 (`runner survives errors`).

## File Structure

```
orange/                         (ở gốc repo, cạnh project/)
  Project.toml, Manifest.toml
  src/Orange.jl                 module, exports
  src/io.jl                     Instance, read_instance
  src/ecmp.jl                   Routing, routing, ecmp_split, pathcount_split, build_r
  src/verify.jl                 changes, utilization, direct_paths, max_utilization,
                                base_mlu, check_solution, write_srpaths, write_loads
  src/model.jl                  build_model, extract_paths, lex_second_stage!
  src/experiment.jl             run_instance
  src/heuristic.jl              local_search                     (Task 11, tùy chọn)
  test/runtests.jl
  test/toy/toy-{net,tm,scenario}.json
  scripts/run_experiments.jl
  scripts/make_tables.jl
  scripts/budget_sensitivity.jl                                  (Task 9, tùy chọn)
  scripts/compare_r_modes.jl                                     (Task 10, tùy chọn)
  results/                      CSV, srpaths, log
report/
  report.tex, table_P1.tex, table_P2.tex
project/KE_HOACH_THUC_HIEN.md   (file này)
```

## Lịch thực hiện (hôm nay T2 19/10, hạn CN 25/10)

| Ngày | Việc | Trạng thái |
|---|---|---|
| T2 19/10 | Task 0 (gửi câu hỏi cho thầy, setup), Task 1, Task 2 | ☐ |
| T3 20/10 | Task 3, 4, 5 | ☐ |
| T4 21/10 | Task 6; tối: chạy Task 7 phần $t=0$ qua đêm (≤ 10 giờ) | ☐ |
| T5 22/10 | Task 7 phần $t=0,1$ chạy nền; Task 11 (heuristic); viết phần 1–2 của báo cáo | ☐ |
| T6 23/10 | Chạy heuristic cho các instance lớn (sau khi Task 7 xong, để không làm nhiễu thời gian đo); Task 8 (bảng, biểu đồ) | ☐ |
| T7 24/10 | Hoàn thiện báo cáo; tùy chọn: Task 9, 10 trên instance nhỏ | ☐ |
| CN 25/10 | Dự phòng, nộp | ☐ |

**Chính sách số lần chạy (chờ thầy xác nhận):** 20 instance × 10 lần × 1800 s là 100 giờ, không khả thi. Mặc định: chạy lần 1; nếu lần 1 xong dưới 120 s thì chạy đủ 10 lần, nếu không chỉ chạy 1 lần và **ghi rõ trong báo cáo** (cột "Runs"). Instance vượt `max_vars` (3·10⁶ biến) ghi `SKIPPED_TOO_LARGE`.

## Thứ tự ưu tiên

- **Bắt buộc:** Task 0–8 (đáp ứng readme).
- **Cải thiện có trong các task bắt buộc** (chi phí thấp): khởi tạo solver bằng nghiệm không waypoint (Task 3), cố định demand có lưu lượng 0 (Task 3), cột MLU ban đầu và % cải thiện (Task 6, 8), biểu đồ tải đã sắp xếp (Task 6, 8), hỗ trợ hai cách tính $r$ (Task 2).
- **Khuyến nghị mạnh:** Task 11 (heuristic). Lý do: MILP theo mô hình của đề chỉ dựng được cho khoảng 5–9/20 instance (xem Task 5 Step 3). Không có heuristic thì bảng kết quả có 11–15 dòng "không chạy". Heuristic cho mỗi instance một nghiệm và % cải thiện so với định tuyến thường. Làm sau Task 6, trong lúc Task 7 chạy nền.
- **Tùy chọn, nếu còn thời gian:** Task 9 (độ nhạy ngân sách), Task 10 (so sánh cách tính $r$), Task 12 (mục tiêu lexicographic hai bước).
- **Ghi chú, không có task:** dùng Gurobi nếu có giấy phép học thuật (chỉ đổi `HiGHS.Optimizer` thành `Gurobi.Optimizer`); giới hạn waypoint vào tập ứng viên K nút (nếu làm phải ghi rõ là bài toán hạn chế).

---

### Task 0: Câu hỏi cho thầy, khởi tạo package và dữ liệu toy

**Files:**
- Create: `orange/Project.toml`, `orange/src/Orange.jl`, `orange/src/{io,ecmp,verify,model,experiment}.jl`, `orange/test/runtests.jl`
- Create: `orange/test/toy/toy-net.json`, `toy-tm.json`, `toy-scenario.json`

**Interfaces:**
- Produces: module `Orange` với danh sách export cố định; ba file toy khớp mục 5.1 của đề.

- [ ] **Step 1: Gửi câu hỏi cho thầy (ngày đầu tiên)**

Nội dung gợi ý (readme viết bằng tiếng Anh nên gửi bằng tiếng Anh):
```
1. The subject (Fig. 1, Table 2) defines r(u,v,a,t) by ECMP per-hop even splitting
   (r(v0,v5,a14,0)=0.5), while calculating_r.pdf gives the path-count ratio
   sigma_iu*sigma_vj/sigma_ij (=2/3 on the same arc). Which one should we use?
2. Step 9 says "for only time period 0" but describes the model with period 1 and
   the budget constraints. Should step 9 solve periods 0 and 1 together?
3. "Average on ten runs" with 1800 s/3600 s limits on 20 instances may need over
   100 hours. May we run 10 times only for instances solved quickly, and once otherwise?
4. Objective: is minimizing the maximum link utilization acceptable instead of the
   lexicographic objective (5)?
5. Gap: confirm gap = 1 - (best lower bound)/(best solution value).
6. Steps 8-9: should periods 0 and 1 be optimized jointly (one model, as in the
   subject), or should period 1 be optimized with the period-0 routing fixed?
7. The arc-segment model has |D|*n(n-1) binaries per period: about 5e6 for setA-06
   and 1e9 for setA-20, beyond what a MILP solver can build on our 32 GB machine.
   For such instances, may we report "model too large" and add a heuristic
   (local search on waypoints) as a complement?
```
Ghi câu trả lời vào cuối file này (mục "Nhật ký quyết định").

- [ ] **Step 2: Tạo package và cài thư viện**

```bash
cd C:/Users/X1/Project/SOICT_mathematical_modelling
git checkout -b feature/tasr
mkdir -p orange/src orange/test/toy orange/scripts orange/results report
julia --project=orange -e 'using Pkg; Pkg.add(["JuMP","HiGHS","Graphs","JSON3","Random","Statistics","Test"])'
```
Expected: có `orange/Project.toml` và `orange/Manifest.toml`. Thêm vào đầu `orange/Project.toml`:
```toml
name = "Orange"
uuid = "7f3a8c2e-1b4d-4e6a-9c55-0a1b2c3d4e5f"
version = "0.1.0"
```

- [ ] **Step 3: Tạo module**

`orange/src/Orange.jl`:
```julia
module Orange
using JuMP, HiGHS, Graphs, SparseArrays, JSON3, Random
include("io.jl")
include("ecmp.jl")
include("verify.jl")
include("model.jl")
include("experiment.jl")
include("heuristic.jl")
export Instance, read_instance,
       Routing, routing, ecmp_split, pathcount_split, build_r,
       changes, utilization, direct_paths, max_utilization, base_mlu,
       check_solution, write_srpaths, write_loads,
       build_model, extract_paths, lex_second_stage!,
       run_instance, local_search
end
```
Tạo 6 file `io.jl ecmp.jl verify.jl model.jl experiment.jl heuristic.jl` trong `orange/src/`, mỗi file chỉ có một dòng `# filled in by a later task`.

`orange/test/runtests.jl` (khung, các task sau thêm testset vào cuối):
```julia
using Test, Orange, JuMP, HiGHS
const TOY = joinpath(@__DIR__, "toy", "toy")
const SETA = joinpath(@__DIR__, "..", "..", "project", "setA")
const OPT = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.0, "threads" => 1)
arc(inst, id) = findfirst(==(id), inst.link_id)
```

- [ ] **Step 4: Tạo dữ liệu toy** (đúng mục 5.1 của đề)

`orange/test/toy/toy-net.json`:
```json
{"directed": true, "multigraph": false,
 "nodes": [{"name":"A","id":0},{"name":"B","id":1},{"name":"C","id":2},{"name":"D","id":3},{"name":"E","id":4},{"name":"F","id":5},{"name":"G","id":6}],
 "links": [
 {"id":0,"from":0,"to":1,"metric":100,"capacity":400},
 {"id":1,"from":0,"to":2,"metric":200,"capacity":300},
 {"id":2,"from":1,"to":3,"metric":200,"capacity":200},
 {"id":3,"from":1,"to":4,"metric":100,"capacity":200},
 {"id":4,"from":2,"to":4,"metric":100,"capacity":400},
 {"id":5,"from":2,"to":6,"metric":300,"capacity":200},
 {"id":6,"from":3,"to":5,"metric":100,"capacity":200},
 {"id":7,"from":3,"to":4,"metric":100,"capacity":200},
 {"id":8,"from":4,"to":5,"metric":300,"capacity":200},
 {"id":9,"from":4,"to":6,"metric":100,"capacity":200},
 {"id":10,"from":5,"to":6,"metric":100,"capacity":200},
 {"id":11,"from":1,"to":0,"metric":100,"capacity":400},
 {"id":12,"from":2,"to":0,"metric":200,"capacity":300},
 {"id":13,"from":3,"to":1,"metric":200,"capacity":200},
 {"id":14,"from":4,"to":1,"metric":100,"capacity":200},
 {"id":15,"from":4,"to":2,"metric":100,"capacity":400},
 {"id":16,"from":6,"to":2,"metric":300,"capacity":200},
 {"id":17,"from":5,"to":3,"metric":100,"capacity":200},
 {"id":18,"from":4,"to":3,"metric":100,"capacity":200},
 {"id":19,"from":5,"to":4,"metric":300,"capacity":200},
 {"id":20,"from":6,"to":4,"metric":100,"capacity":200},
 {"id":21,"from":6,"to":5,"metric":100,"capacity":200}]}
```
`orange/test/toy/toy-tm.json`:
```json
{"num_time_slots": 2, "demands": [{"v":[50.0,100.0],"s":0,"t":5},{"v":[100.0,50.0],"s":2,"t":5}]}
```
`orange/test/toy/toy-scenario.json`:
```json
{"max_segments": 4, "budget": [{"t":1,"value":20}], "interventions": [{"t":1,"links":[2,3]}]}
```

- [ ] **Step 5: Kiểm tra package nạp được**

Run: `julia --project=orange -e 'using Orange; println("ok")'`
Expected: `ok`

- [ ] **Step 6: Commit**

```bash
git add orange project/KE_HOACH_THUC_HIEN.md
git commit -m "chore: scaffold Orange package and toy fixtures"
```

---

### Task 1: Đọc dữ liệu (`Instance`)

**Files:**
- Modify: `orange/src/io.jl` (thay toàn bộ)
- Test: `orange/test/runtests.jl` (thêm vào cuối)

**Interfaces:**
- Produces: `Instance` (đỉnh và cung đánh số từ 1; **thời kỳ $p = t+1$**) với các trường
  `n, m::Int; node_id::Vector{Int}; arc_from, arc_to, link_id::Vector{Int}; omega, cap::Vector{Float64}; dem_s, dem_t::Vector{Int}; vol::Matrix{Float64}` (kích thước `nD×P`); `P, maxseg::Int; budget::Vector{Float64}` (`budget[1]=Inf`); `down::Vector{Vector{Int}}` (chỉ số cung bị tắt ở mỗi thời kỳ).
- Produces: `read_instance(prefix; maxseg=nothing, budget=nothing) -> Instance`. `prefix` ví dụ `".../setA-01"`. `maxseg` ghi đè `max_segments`; `budget` ghi đè ngân sách mọi $p\ge2$ (có thể là `Inf`).

- [ ] **Step 1: Viết test thất bại**

```julia
@testset "io" begin
    inst = read_instance(TOY)
    @test inst.n == 7 && inst.m == 22 && inst.P == 2 && inst.maxseg == 4
    @test inst.vol == [50.0 100.0; 100.0 50.0]
    @test inst.dem_s == [1, 3] && inst.dem_t == [6, 6]      # id JSON + 1
    @test inst.budget[1] == Inf && inst.budget[2] == 20
    @test inst.down[1] == Int[] && inst.down[2] == [3, 4]   # link id 2,3 -> chỉ số 3,4
    @test read_instance(TOY; maxseg=2).maxseg == 2
    @test read_instance(TOY; budget=0).budget[2] == 0
    @test read_instance(TOY; budget=Inf).budget[2] == Inf
end

@testset "setA readable (kể cả multigraph=true)" begin
    for i in 1:20
        inst = read_instance(joinpath(SETA, "setA-" * lpad(i, 2, '0')))
        @test inst.P == 2 && inst.maxseg == 6
        @test length(inst.down[2]) == 1 && isfinite(inst.budget[2])
        @test all(inst.omega .> 0) && all(inst.cap .> 0)
    end
end
```

- [ ] **Step 2: Chạy để thấy test thất bại**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: FAIL, `read_instance` not defined.

- [ ] **Step 3: Cài đặt** — `orange/src/io.jl`:

```julia
struct Instance
    n::Int
    m::Int
    node_id::Vector{Int}
    arc_from::Vector{Int}
    arc_to::Vector{Int}
    link_id::Vector{Int}
    omega::Vector{Float64}
    cap::Vector{Float64}
    dem_s::Vector{Int}
    dem_t::Vector{Int}
    vol::Matrix{Float64}
    P::Int
    maxseg::Int
    budget::Vector{Float64}
    down::Vector{Vector{Int}}
end

function read_instance(prefix::AbstractString; maxseg=nothing, budget=nothing)
    net = JSON3.read(read(prefix * "-net.json", String))
    tm = JSON3.read(read(prefix * "-tm.json", String))
    sc = JSON3.read(read(prefix * "-scenario.json", String))

    node_id = Int[Int(x.id) for x in net.nodes]
    allunique(node_id) || error("duplicate node ids")
    v_of = Dict(id => k for (k, id) in enumerate(node_id))

    links = net.links
    link_id = Int[Int(l.id) for l in links]
    allunique(link_id) || error("duplicate link ids")
    arc_from = Int[v_of[Int(l["from"])] for l in links]
    arc_to = Int[v_of[Int(l["to"])] for l in links]
    # cờ "multigraph" bị bỏ qua: tự kiểm tra
    allunique(collect(zip(arc_from, arc_to))) || error("parallel arcs are not supported")
    any(arc_from .== arc_to) && error("self loops are not supported")
    omega = Float64[Float64(l.metric) for l in links]
    cap = Float64[Float64(l.capacity) for l in links]
    arc_of_link = Dict(id => a for (a, id) in enumerate(link_id))

    P = Int(tm.num_time_slots)
    dems = tm.demands
    dem_s = Int[v_of[Int(d.s)] for d in dems]
    dem_t = Int[v_of[Int(d.t)] for d in dems]
    vol = zeros(length(dems), P)
    for (k, d) in enumerate(dems), p in 1:P
        vol[k, p] = Float64(d.v[p])
    end

    bud = fill(Inf, P)
    for b in sc.budget
        bud[Int(b.t) + 1] = Float64(b.value)
    end
    budget === nothing || (bud[2:end] .= Float64(budget))

    down = [Int[] for _ in 1:P]
    for iv in sc.interventions, id in iv.links
        push!(down[Int(iv.t) + 1], arc_of_link[Int(id)])
    end

    ms = maxseg === nothing ? Int(sc.max_segments) : Int(maxseg)
    return Instance(length(node_id), length(links), node_id, arc_from, arc_to, link_id,
                    omega, cap, dem_s, dem_t, vol, P, ms, bud, down)
end
```

- [ ] **Step 4: Chạy để thấy test đạt**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: PASS (`io`, `setA readable`).

- [ ] **Step 5: Commit**

```bash
git add orange && git commit -m "feat: read instances from json"
```

---

### Task 2: Hệ số tách $r$ (ECMP từng chặng và đếm đường)

**Files:**
- Modify: `orange/src/ecmp.jl` (thay toàn bộ)
- Test: `orange/test/runtests.jl`

**Interfaces:**
- Consumes: `Instance`.
- Produces:
  - `routing(inst, p) -> Routing` với `D::Matrix{Float64}` (khoảng cách ngắn nhất trên $G_p$), `S::Matrix{Float64}` (số đường ngắn nhất), `out::Vector{Vector{Int}}` (cung ra còn hoạt động).
  - `ecmp_split(inst, R, u, v) -> Dict{Int,Float64}`, `pathcount_split(inst, R, u, v) -> Dict{Int,Float64}`: chỉ số cung → tỷ lệ luồng; rỗng nếu `u==v` hoặc không tới được.
  - `build_r(inst, p; mode=:ecmp) -> Dict{Tuple{Int,Int},Vector{Pair{Int,Float64}}}` cho mọi cặp $i\ne j$ **có đường**; cặp không tới được không có khóa. `mode ∈ (:ecmp, :pathcount)`.

- [ ] **Step 1: Viết test thất bại**

```julia
@testset "ecmp toy (Bảng 2 của đề)" begin
    inst = read_instance(TOY)
    R = routing(inst, 1)
    f = ecmp_split(inst, R, 1, 6)                        # v0 -> v5
    @test f[arc(inst, 0)] ≈ 1.0                          # a0,1
    @test f[arc(inst, 2)] ≈ 0.5                          # a1,3
    @test f[arc(inst, 3)] ≈ 0.5                          # a1,4
    @test f[arc(inst, 6)] ≈ 0.75                         # a3,5
    @test f[arc(inst, 18)] ≈ 0.25                        # a4,3
    @test f[arc(inst, 9)] ≈ 0.25                         # a4,6
    @test f[arc(inst, 21)] ≈ 0.25                        # a6,5 (id 21: 6->5)
    g = ecmp_split(inst, R, 3, 6)                        # v2 -> v5
    @test g[arc(inst, 4)] ≈ 1.0 && g[arc(inst, 9)] ≈ 0.5
    @test (f[arc(inst, 9)] * 50 + g[arc(inst, 9)] * 100) / 200 ≈ 0.3125
end

@testset "pathcount toy (calculating_r.pdf)" begin
    inst = read_instance(TOY)
    f = pathcount_split(inst, routing(inst, 1), 1, 6)
    @test f[arc(inst, 0)] ≈ 1.0
    @test f[arc(inst, 3)] ≈ 2 / 3                        # khác ECMP (0.5)
    @test f[arc(inst, 2)] ≈ 1 / 3
    r = build_r(inst, 1; mode=:pathcount)
    @test Dict(r[(1, 6)])[arc(inst, 3)] ≈ 2 / 3
    @test_throws ErrorException build_r(inst, 1; mode=:other)
end

@testset "ecmp down arcs" begin
    inst = read_instance(TOY)
    f = ecmp_split(inst, routing(inst, 2), 1, 6)         # a1,3 và a1,4 bị tắt
    @test !haskey(f, arc(inst, 2)) && !haskey(f, arc(inst, 3))
    @test !isempty(f)
    r = build_r(inst, 2)
    @test all(q -> !(first(q) in inst.down[2]), (q for lst in values(r) for q in lst))
end

@testset "ecmp float ties" begin
    dir = mktempdir()
    write(joinpath(dir, "t-net.json"), """{"directed":true,"multigraph":true,"graph":{},
      "nodes":[{"name":"a","id":0},{"name":"b","id":1},{"name":"c","id":2},{"name":"d","id":3}],
      "links":[{"id":0,"from":0,"to":1,"metric":0.1,"capacity":1},{"id":1,"from":1,"to":3,"metric":0.2,"capacity":1},
               {"id":2,"from":0,"to":2,"metric":0.15,"capacity":1},{"id":3,"from":2,"to":3,"metric":0.15,"capacity":1}]}""")
    write(joinpath(dir, "t-tm.json"), """{"num_time_slots":1,"demands":[{"v":[1.0],"s":0,"t":3}]}""")
    write(joinpath(dir, "t-scenario.json"), """{"max_segments":2,"budget":[],"interventions":[]}""")
    inst = read_instance(joinpath(dir, "t"))
    f = ecmp_split(inst, routing(inst, 1), 1, 4)
    # 0.1+0.2 = 0.30000000000000004 và 0.15+0.15 = 0.3 phải hòa: 4 cung, mỗi cung 0.5
    @test length(f) == 4 && all(≈(0.5), values(f))
end
```

- [ ] **Step 2: Chạy để thấy test thất bại**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: FAIL, `routing` not defined.

- [ ] **Step 3: Cài đặt** — `orange/src/ecmp.jl`:

```julia
const RTOL = 1e-9
isclose(a, b) = isapprox(a, b; rtol=RTOL, atol=1e-12)

struct Routing
    D::Matrix{Float64}          # D[u,v]: khoảng cách ngắn nhất trong G_p
    S::Matrix{Float64}          # S[u,v]: số đường ngắn nhất (cho :pathcount)
    out::Vector{Vector{Int}}    # out[x]: cung ra còn hoạt động của x
end

function routing(inst::Instance, p::Int)
    n = inst.n
    active = [a for a in 1:inst.m if !(a in inst.down[p])]
    g = SimpleDiGraph(n)
    out = [Int[] for _ in 1:n]
    for a in active
        add_edge!(g, inst.arc_from[a], inst.arc_to[a])
        push!(out[inst.arc_from[a]], a)
    end
    W = sparse(inst.arc_from[active], inst.arc_to[active], inst.omega[active], n, n)
    D = Matrix{Float64}(undef, n, n)
    for s in 1:n
        D[s, :] = dijkstra_shortest_paths(g, s, W).dists
    end
    # đếm đường ngắn nhất theo thứ tự khoảng cách, so sánh có dung sai
    S = zeros(n, n)
    for s in 1:n
        S[s, s] = 1.0
        for x in sort([x for x in 1:n if isfinite(D[s, x])], by=x -> D[s, x]), a in out[x]
            y = inst.arc_to[a]
            isclose(D[s, x] + inst.omega[a], D[s, y]) && (S[s, y] += S[s, x])
        end
    end
    return Routing(D, S, out)
end

"Luồng đơn vị từ u đến v, chia đều tại mỗi nút cho các cung ra thuộc FG(u,v)."
function ecmp_split(inst::Instance, R::Routing, u::Int, v::Int)
    res = Dict{Int,Float64}()
    D = R.D
    (u == v || !isfinite(D[u, v])) && return res
    nodes = [x for x in 1:inst.n if isfinite(D[u, x]) && isfinite(D[x, v]) &&
             isclose(D[u, x] + D[x, v], D[u, v])]
    sort!(nodes, by=x -> D[u, x])
    flow = zeros(inst.n)
    flow[u] = 1.0
    for x in nodes
        x == v && continue
        outs = [a for a in R.out[x] if isfinite(D[inst.arc_to[a], v]) &&
                isclose(D[u, x] + inst.omega[a] + D[inst.arc_to[a], v], D[u, v])]
        isempty(outs) && continue
        share = flow[x] / length(outs)
        for a in outs
            res[a] = get(res, a, 0.0) + share
            flow[inst.arc_to[a]] += share
        end
    end
    return res
end

"Tỷ lệ số đường ngắn nhất đi qua cung (công thức của calculating_r.pdf)."
function pathcount_split(inst::Instance, R::Routing, u::Int, v::Int)
    res = Dict{Int,Float64}()
    D, S = R.D, R.S
    (u == v || !isfinite(D[u, v])) && return res
    for x in 1:inst.n, a in R.out[x]
        y = inst.arc_to[a]
        (isfinite(D[u, x]) && isfinite(D[y, v])) || continue
        isclose(D[u, x] + inst.omega[a] + D[y, v], D[u, v]) || continue
        res[a] = S[u, x] * S[y, v] / S[u, v]
    end
    return res
end

function build_r(inst::Instance, p::Int; mode::Symbol=:ecmp)
    split = mode === :ecmp ? ecmp_split :
            mode === :pathcount ? pathcount_split : error("unknown r mode $mode")
    R = routing(inst, p)
    r = Dict{Tuple{Int,Int},Vector{Pair{Int,Float64}}}()
    for i in 1:inst.n, j in 1:inst.n
        i == j && continue
        f = split(inst, R, i, j)
        isempty(f) || (r[(i, j)] = collect(f))
    end
    return r
end
```

- [ ] **Step 4: Chạy để thấy test đạt**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: PASS. Nếu `ecmp float ties` sai, in `routing(inst,1).D` để xem khoảng cách.

- [ ] **Step 5: Commit**

```bash
git add orange && git commit -m "feat: split coefficients (ECMP per-hop and path-count)"
```

---

### Task 3: Mô hình JuMP

**Files:**
- Modify: `orange/src/verify.jl`, `orange/src/model.jl` (thay toàn bộ)
- Test: `orange/test/runtests.jl`

**Interfaces:**
- Consumes: `Instance`, `build_r`.
- Produces (`verify.jl`):
  - `changes(a::Vector{Int}, b::Vector{Int}) -> Int` — số đoạn khác nhau (định nghĩa dist của đề).
  - `utilization(inst, rs, paths, p) -> Vector{Float64}` — tải từng cung tại thời kỳ `p`; `rs[p]` là dict của `build_r`; `paths[(d,p)]` là dãy nút.
  - `direct_paths(inst, P) -> Dict{Tuple{Int,Int},Vector{Int}}` — mọi demand đi thẳng.
  - `max_utilization(inst, rs, paths, P) -> Float64`; `base_mlu(inst, rs, P) -> Float64` (MLU khi không waypoint).
- Produces (`model.jl`):
  - `build_model(inst, rs, P, optimizer; tlimit=Inf, silent=true, eps=1e-7, warm_start=true) -> (model, x, z, load)`: `x[d,p,i,j]` nhị phân, `z` là MLU, `load[p][a]` là biểu thức luồng qua cung `a`. Mục tiêu $\min z + \varepsilon\sum x$ (phạt nhỏ để loại chu trình thừa).
  - `extract_paths(inst, x, P; val=value) -> Dict{Tuple{Int,Int},Vector{Int}}` — tìm đường từ $s$ tới $\tau$ trên các đoạn được chọn bằng BFS, bỏ qua chu trình rời.

- [ ] **Step 1: Viết test thất bại**

```julia
@testset "changes (Bảng 1 của đề)" begin
    @test changes([1, 9, 2], [1, 2]) == 3
    @test changes([1, 5, 6, 2], [1, 5, 2]) == 3
    @test changes([1, 5, 6, 2], [1, 6, 5, 2]) == 6
    @test changes([1, 5, 2], [1, 6, 2]) == 4
end

@testset "toy loads from paths" begin
    inst = read_instance(TOY)
    rs = [build_r(inst, p) for p in 1:2]
    @test base_mlu(inst, rs[1:1], 1) ≈ 0.4375
    wp = Dict((1, 1) => [1, 5, 6], (2, 1) => [3, 6])     # waypoint v4 (chỉ số 5) cho d0
    @test max_utilization(inst, rs, wp, 1) ≈ 0.375
end

# vét cạn: mỗi demand đi thẳng hoặc qua đúng 1 waypoint (tương ứng maxSeg = 2)
function brute_best(inst, P)
    n, nD = inst.n, length(inst.dem_s)
    rs = [build_r(inst, p) for p in 1:P]
    seq(d, w) = w == 0 ? [inst.dem_s[d], inst.dem_t[d]] : [inst.dem_s[d], w, inst.dem_t[d]]
    opts = [[w for w in 0:n if w == 0 || (w != inst.dem_s[d] && w != inst.dem_t[d])] for d in 1:nD]
    joint = collect(Iterators.product(opts...))
    u = [[maximum(utilization(inst, rs, Dict((d, p) => seq(d, c[d]) for d in 1:nD), p)) for c in joint] for p in 1:P]
    best = Inf
    for (i0, c0) in enumerate(joint)
        if P == 1
            best = min(best, u[1][i0]); continue
        end
        for (i1, c1) in enumerate(joint)
            ch = sum(changes(seq(d, c0[d]), seq(d, c1[d])) for d in 1:nD)
            ch <= inst.budget[2] && (best = min(best, max(u[1][i0], u[2][i1])))
        end
    end
    return best
end

@testset "model t=0 equals brute force (maxSeg=2)" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, 1)]
    model, x, z = build_model(inst, rs, 1, OPT)
    @test start_value(x[1, 1, 1, 6]) == 1.0                  # khởi tạo = đi thẳng
    @test start_value(z) ≈ 0.4375
    optimize!(model)
    @test termination_status(model) == MOI.OPTIMAL
    @test value(z) ≈ brute_best(inst, 1) atol = 1e-6
    @test value(z) <= 0.375 + 1e-9
end

@testset "zero-volume demand is fixed to direct path" begin
    dir = mktempdir()
    for f in ("net", "scenario"); cp(TOY * "-$f.json", joinpath(dir, "z-$f.json")); end
    write(joinpath(dir, "z-tm.json"), """{"num_time_slots":2,"demands":[{"v":[0.0,0.0],"s":0,"t":5},{"v":[100.0,50.0],"s":2,"t":5}]}""")
    inst = read_instance(joinpath(dir, "z"); maxseg=2)
    rs = [build_r(inst, p) for p in 1:2]
    model, x, z = build_model(inst, rs, 2, OPT)
    @test is_fixed(x[1, 1, 1, 6]) && fix_value(x[1, 1, 1, 6]) == 1.0
    optimize!(model)
    @test termination_status(model) == MOI.OPTIMAL
    @test value(z) ≈ brute_best(inst, 2) atol = 1e-6
end

@testset "unreachable segments are forbidden" begin
    dir = mktempdir()
    write(joinpath(dir, "l-net.json"), """{"directed":true,"multigraph":false,
      "nodes":[{"name":"a","id":0},{"name":"b","id":1},{"name":"c","id":2}],
      "links":[{"id":0,"from":0,"to":1,"metric":1,"capacity":10},{"id":1,"from":1,"to":2,"metric":1,"capacity":10}]}""")
    write(joinpath(dir, "l-tm.json"), """{"num_time_slots":1,"demands":[{"v":[5.0],"s":0,"t":2}]}""")
    write(joinpath(dir, "l-scenario.json"), """{"max_segments":3,"budget":[],"interventions":[]}""")
    inst = read_instance(joinpath(dir, "l"))
    model, x, z = build_model(inst, [build_r(inst, 1)], 1, OPT)
    @test is_fixed(x[1, 1, 3, 1]) && fix_value(x[1, 1, 3, 1]) == 0.0
    optimize!(model)
    @test value(z) ≈ 0.5
    @test extract_paths(inst, x, 1)[(1, 1)] in ([1, 3], [1, 2, 3])
end

@testset "extract_paths ignores cycles" begin
    inst = read_instance(TOY)
    rs = [build_r(inst, 1)]
    model, x, z = build_model(inst, rs, 1, OPT)
    # d1: đường 1->2->6, cộng chu trình rời 3<->4 và chu trình 2<->4 chạm vào đường
    fake = Dict(x[1, 1, 1, 2] => 1.0, x[1, 1, 2, 6] => 1.0,
                x[1, 1, 3, 4] => 1.0, x[1, 1, 4, 3] => 1.0,
                x[1, 1, 2, 4] => 1.0, x[1, 1, 4, 2] => 1.0,
                x[2, 1, 3, 6] => 1.0)
    paths = extract_paths(inst, x, 1; val=v -> get(fake, v, 0.0))
    @test paths[(1, 1)] == [1, 2, 6]
    @test paths[(2, 1)] == [3, 6]
end
```

- [ ] **Step 2: Chạy để thấy test thất bại**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: FAIL, `changes` not defined.

- [ ] **Step 3: Cài đặt** — `orange/src/verify.jl`:

```julia
"Số đoạn khác nhau giữa hai đường segment (dist của đề)."
function changes(a::Vector{Int}, b::Vector{Int})
    return length(symdiff(Set(zip(a, a[2:end])), Set(zip(b, b[2:end]))))
end

"Tải (luồng / dung lượng) từng cung tại thời kỳ p, tính độc lập với solver."
function utilization(inst::Instance, rs, paths, p::Int)
    load = zeros(inst.m)
    for d in eachindex(inst.dem_s)
        seq = paths[(d, p)]
        for (u, v) in zip(seq, seq[2:end])
            haskey(rs[p], (u, v)) || error("segment ($u,$v) has no route in period $p")
            for (a, fr) in rs[p][(u, v)]
                load[a] += fr * inst.vol[d, p]
            end
        end
    end
    return load ./ inst.cap
end

direct_paths(inst::Instance, P::Int) =
    Dict((d, p) => [inst.dem_s[d], inst.dem_t[d]] for d in eachindex(inst.dem_s), p in 1:P)

max_utilization(inst::Instance, rs, paths, P::Int) =
    maximum(maximum(utilization(inst, rs, paths, p)) for p in 1:P)

base_mlu(inst::Instance, rs, P::Int) = max_utilization(inst, rs, direct_paths(inst, P), P)
```

`orange/src/model.jl`:
```julia
function build_model(inst::Instance, rs, P::Int, optimizer;
                     tlimit=Inf, silent=true, eps=1e-7, warm_start=true)
    n, nD = inst.n, length(inst.dem_s)
    model = Model(optimizer)
    silent && set_silent(model)
    isfinite(tlimit) && set_time_limit_sec(model, tlimit)

    @variable(model, x[d=1:nD, p=1:P, i=1:n, j=1:n; i != j], Bin)
    @variable(model, z >= 0)

    # đoạn không có đường trong G_p bị cấm
    for p in 1:P, i in 1:n, j in 1:n
        (i == j || haskey(rs[p], (i, j))) && continue
        for d in 1:nD
            fix(x[d, p, i, j], 0.0; force=true)
        end
    end

    # demand có lưu lượng 0 ở mọi thời kỳ: đi thẳng (không ảnh hưởng tải, dist = 0)
    for d in 1:nD
        all(iszero, inst.vol[d, 1:P]) || continue
        s, t = inst.dem_s[d], inst.dem_t[d]
        all(p -> haskey(rs[p], (s, t)), 1:P) || continue
        for p in 1:P, i in 1:n, j in 1:n
            i == j && continue
            fix(x[d, p, i, j], (i == s && j == t) ? 1.0 : 0.0; force=true)
        end
    end

    # (1) bảo toàn luồng
    for d in 1:nD, p in 1:P, i in 1:n
        rhs = i == inst.dem_s[d] ? 1 : (i == inst.dem_t[d] ? -1 : 0)
        @constraint(model, sum(x[d, p, i, j] for j in 1:n if j != i) -
                           sum(x[d, p, j, i] for j in 1:n if j != i) == rhs)
    end

    # (2) số đoạn
    for d in 1:nD, p in 1:P
        @constraint(model, sum(x[d, p, i, j] for i in 1:n, j in 1:n if i != j) <= inst.maxseg)
    end

    # (3) tải, z là MLU
    load = [[AffExpr(0.0) for _ in 1:inst.m] for _ in 1:P]
    for p in 1:P
        for ((i, j), lst) in rs[p], (a, fr) in lst, d in 1:nD
            c = fr * inst.vol[d, p]
            c == 0 && continue
            add_to_expression!(load[p][a], c, x[d, p, i, j])
        end
        for a in 1:inst.m
            a in inst.down[p] && continue
            @constraint(model, load[p][a] <= inst.cap[a] * z)
        end
    end

    # (4) ngân sách giữa p-1 và p
    ys = []
    for p in 2:P
        isfinite(inst.budget[p]) || continue
        y = @variable(model, [d=1:nD, i=1:n, j=1:n; i != j], lower_bound = 0)
        push!(ys, y)
        for d in 1:nD, i in 1:n, j in 1:n
            i == j && continue
            @constraint(model, y[d, i, j] >= x[d, p, i, j] - x[d, p-1, i, j])
            @constraint(model, y[d, i, j] >= x[d, p-1, i, j] - x[d, p, i, j])
        end
        @constraint(model, sum(y[d, i, j] for d in 1:nD, i in 1:n, j in 1:n if i != j) <= inst.budget[p])
    end

    @objective(model, Min, z + eps * sum(x))

    # khởi tạo bằng nghiệm "đi thẳng" (luôn khả thi: dist = 0)
    if warm_start && all(haskey(rs[p], (inst.dem_s[d], inst.dem_t[d])) for d in 1:nD, p in 1:P)
        for d in 1:nD, p in 1:P, i in 1:n, j in 1:n
            i == j && continue
            set_start_value(x[d, p, i, j], (i == inst.dem_s[d] && j == inst.dem_t[d]) ? 1.0 : 0.0)
        end
        set_start_value(z, base_mlu(inst, rs, P))
        for y in ys, v in y
            set_start_value(v, 0.0)
        end
    end
    return model, x, z, load
end

"Đường s -> τ trên các đoạn được chọn (BFS, bỏ qua chu trình rời)."
function extract_paths(inst::Instance, x, P::Int; val=value)
    n = inst.n
    paths = Dict{Tuple{Int,Int},Vector{Int}}()
    for d in eachindex(inst.dem_s), p in 1:P
        s, t = inst.dem_s[d], inst.dem_t[d]
        succ = [Int[] for _ in 1:n]
        for i in 1:n, j in 1:n
            i != j && val(x[d, p, i, j]) > 0.5 && push!(succ[i], j)
        end
        prev = zeros(Int, n)
        prev[s] = s
        queue = [s]
        while !isempty(queue)
            u = popfirst!(queue)
            u == t && break
            for v in succ[u]
                prev[v] == 0 || continue
                prev[v] = u
                push!(queue, v)
            end
        end
        prev[t] == 0 && error("no s-t path for demand $d period $p")
        seq = [t]
        while seq[1] != s
            pushfirst!(seq, prev[seq[1]])
        end
        paths[(d, p)] = seq
    end
    return paths
end
```

- [ ] **Step 4: Chạy để thấy test đạt**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: PASS. Nếu `model t=0 equals brute force` lệch: in `value(z)`, `brute_best(inst,1)` và đường trích ra để so.

- [ ] **Step 5: Commit**

```bash
git add orange && git commit -m "feat: JuMP model with warm start, path extraction, independent load check"
```

---

### Task 4: Kiểm tra nghiệm, xuất `srpaths` và tải đã sắp xếp

**Files:**
- Modify: `orange/src/verify.jl` (thêm vào cuối)
- Test: `orange/test/runtests.jl`

**Interfaces:**
- Consumes: `utilization`, `changes`, `direct_paths`, `extract_paths`.
- Produces:
  - `check_solution(inst, rs, paths, P, z; tol=1e-6) -> (mlu=Float64, budget_ok=Bool)`: ném lỗi nếu MLU tính lại **lớn hơn** $z$ (nhỏ hơn là hợp lệ, do chu trình thừa bị bỏ).
  - `write_srpaths(inst, paths, P, file)`: JSON đúng định dạng đề, `d` và `t` đánh số từ 0, `w` là `id` nút JSON; bỏ demand không có waypoint.
  - `write_loads(inst, rs, paths, P, file)`: CSV `rank,base,opt` gồm tải (sắp giảm dần) của mọi cặp (cung hoạt động, thời kỳ) khi đi thẳng và khi tối ưu.

- [ ] **Step 1: Viết test thất bại**

```julia
@testset "solution check, srpaths, loads (t=0,1)" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, p) for p in 1:2]
    model, x, z = build_model(inst, rs, 2, OPT)
    optimize!(model)
    @test termination_status(model) == MOI.OPTIMAL
    paths = extract_paths(inst, x, 2)
    chk = check_solution(inst, rs, paths, 2, value(z))
    @test chk.budget_ok
    @test chk.mlu ≈ value(z) atol = 1e-6
    @test value(z) ≈ brute_best(inst, 2) atol = 1e-6
    f = tempname() * ".json"
    write_srpaths(inst, paths, 2, f)
    js = Orange.JSON3.read(read(f, String))
    @test all(e -> e.t in (0, 1) && e.d in (0, 1) && !isempty(e.w), js.srpaths)
    g = tempname() * ".csv"
    write_loads(inst, rs, paths, 2, g)
    lines = readlines(g)
    @test lines[1] == "rank,base,opt"
    @test parse(Float64, split(lines[2], ",")[2]) ≈ base_mlu(inst, rs, 2)
    @test_throws ErrorException check_solution(inst, rs, paths, 2, value(z) - 0.1)
end

@testset "budget 0 forces identical routing" begin
    inst = read_instance(TOY; maxseg=2, budget=0)
    rs = [build_r(inst, p) for p in 1:2]
    model, x, z = build_model(inst, rs, 2, OPT)
    optimize!(model)
    paths = extract_paths(inst, x, 2)
    @test all(d -> paths[(d, 1)] == paths[(d, 2)], 1:2)
    @test value(z) ≈ brute_best(inst, 2) atol = 1e-6
end
```

- [ ] **Step 2: Chạy để thấy test thất bại**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: FAIL, `check_solution` not defined.

- [ ] **Step 3: Cài đặt** (thêm vào cuối `orange/src/verify.jl`)

```julia
function check_solution(inst::Instance, rs, paths, P::Int, z::Real; tol=1e-6)
    mlu = max_utilization(inst, rs, paths, P)
    mlu <= z + tol * max(1.0, abs(z)) || error("recomputed MLU $mlu exceeds solver z=$z")
    budget_ok = true
    for p in 2:P
        isfinite(inst.budget[p]) || continue
        ch = sum(changes(paths[(d, p-1)], paths[(d, p)]) for d in eachindex(inst.dem_s))
        ch <= inst.budget[p] || (budget_ok = false)
    end
    return (mlu=mlu, budget_ok=budget_ok)
end

function write_srpaths(inst::Instance, paths, P::Int, file::AbstractString)
    entries = Dict{String,Any}[]
    for d in eachindex(inst.dem_s), p in 1:P
        seq = paths[(d, p)]
        length(seq) > 2 || continue
        push!(entries, Dict("d" => d - 1, "t" => p - 1, "w" => [inst.node_id[v] for v in seq[2:end-1]]))
    end
    open(io -> JSON3.pretty(io, Dict("srpaths" => entries)), file, "w")
end

function write_loads(inst::Instance, rs, paths, P::Int, file::AbstractString)
    collect_loads(ps) = sort(vcat([utilization(inst, rs, ps, p)[[a for a in 1:inst.m if !(a in inst.down[p])]]
                                   for p in 1:P]...); rev=true)
    base = collect_loads(direct_paths(inst, P))
    opt = collect_loads(paths)
    open(file, "w") do io
        println(io, "rank,base,opt")
        for k in eachindex(base)
            println(io, "$k,$(base[k]),$(opt[k])")
        end
    end
end
```

- [ ] **Step 4: Chạy để thấy test đạt**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add orange && git commit -m "feat: solution check, srpaths and sorted-load export"
```

---

### Task 5: Kiểm tra $t=1$ trên toy và chạy thử setA-01

**Files:**
- Test: `orange/test/runtests.jl`

**Interfaces:**
- Consumes: mọi hàm của Task 1–4.

- [ ] **Step 1: Viết test**

```julia
@testset "toy t=0,1 with maxSeg=4 (có thể có chu trình)" begin
    inst = read_instance(TOY)
    rs = [build_r(inst, p) for p in 1:2]
    model, x, z = build_model(inst, rs, 2, OPT; tlimit=120)
    optimize!(model)
    @test termination_status(model) == MOI.OPTIMAL
    paths = extract_paths(inst, x, 2)
    chk = check_solution(inst, rs, paths, 2, value(z))
    @test chk.budget_ok
    @test chk.mlu <= base_mlu(inst, rs, 2) + 1e-9
    @test chk.mlu <= brute_best(read_instance(TOY; maxseg=2), 2) + 1e-6   # nhiều đoạn hơn không tệ hơn
end

@testset "setA-01 smoke (t=0)" begin
    inst = read_instance(joinpath(SETA, "setA-01"))
    rs = [build_r(inst, 1)]
    model, x, z = build_model(inst, rs, 1, OPT; tlimit=120)
    t = @elapsed optimize!(model)
    @info "setA-01 t=0" termination_status(model) value(z) base_mlu(inst, rs, 1) t
    @test has_values(model)
    chk = check_solution(inst, rs, extract_paths(inst, x, 1), 1, value(z); tol=1e-5)
    @test chk.mlu <= base_mlu(inst, rs, 1) + 1e-9
end
```

- [ ] **Step 2: Chạy**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: PASS. Ghi lại thời gian và MLU của setA-01 (dòng `@info`) để ước lượng thời gian các instance sau. setA-01 chỉ có 15 200 biến; nếu không xong trong 120 s, xem lại mô hình trước khi sang Task 6.

- [ ] **Step 3: Hiệu chỉnh ngưỡng `max_vars` theo bộ nhớ thật** (máy có 32 GB RAM)

Số biến $x$ theo instance ($|D|\cdot n(n-1)$ mỗi thời kỳ): 01–05 từ 15 nghìn đến 990 nghìn; 06–09 từ 4,5 đến 7,9 triệu; 10–20 từ 16 triệu đến 958 triệu. Với `max_vars = 3·10⁶` chỉ 01–05 được chạy. Đo bộ nhớ thật để quyết định có nâng ngưỡng cho 06–09 không:
```bash
julia --project=orange -e '
using Orange, JuMP, HiGHS
for i in (4, 5, 6)
    inst = read_instance("project/setA/setA-" * lpad(i, 2, "0"))
    st = @timed begin
        rs = [build_r(inst, 1)]
        build_model(inst, rs, 1, HiGHS.Optimizer)
    end
    println("setA-0$i: build ", round(st.time, digits=1), " s, alloc ", round(st.bytes / 2^30, digits=2), " GiB, free RAM ", round(Sys.free_memory() / 2^30, digits=1), " GiB")
end'
```
Expected: in thời gian và bộ nhớ dựng mô hình. Quy tắc: nếu dựng setA-06 dùng dưới khoảng 8 GiB thì nâng `max_vars` lên `1e7` (06–09 sẽ được thử, HiGHS cần thêm bộ nhớ khi giải); nếu không thì giữ `3e6`. Ghi kết quả vào "Nhật ký quyết định". Nếu đổi ngưỡng, sửa giá trị mặc định `max_vars` trong `run_instance` (Task 6).

- [ ] **Step 4: Commit**

```bash
git add orange && git commit -m "test: toy two-period and setA-01 smoke tests"
```

---

### Task 6: Chạy thực nghiệm tự động

**Files:**
- Modify: `orange/src/experiment.jl` (thay toàn bộ)
- Create: `orange/scripts/run_experiments.jl`
- Test: `orange/test/runtests.jl`

**Interfaces:**
- Consumes: mọi hàm trước.
- Produces: `run_instance(prefix, name, P, tlimit; runs=10, fast_threshold=120.0, max_vars=3_000_000, outdir="results", r_mode=:ecmp, budget=nothing, tag="") -> String` (đường dẫn CSV). CSV `"$outdir/$name-P$P$tag.csv"`, cột:
  `instance,P,run,n,m,nD,status,z,mlu,mlu_base,improvement,bound,gap,solve_time,nodes,check`.
  Lần chạy đầu có nghiệm thì ghi thêm `...-srpaths.json` và `...-loads.csv`. Lỗi trong một lần chạy được ghi `status=ERROR`, lô chạy tiếp.

- [ ] **Step 1: Viết test thất bại**

```julia
@testset "runner writes csv and survives errors" begin
    out = mktempdir()
    csv = run_instance(TOY, "toy", 2, 60; runs=2, outdir=out)
    lines = readlines(csv)
    @test startswith(lines[1], "instance,P,run,n,m,nD,status,z,mlu,mlu_base")
    @test length(lines) == 3
    @test split(lines[2], ",")[7] == "Optimal"
    @test isfile(joinpath(out, "toy-P2-srpaths.json")) && isfile(joinpath(out, "toy-P2-loads.csv"))
    # instance không tồn tại: ghi ERROR, không ném lỗi
    csv2 = run_instance(joinpath(out, "missing"), "missing", 1, 10; runs=1, outdir=out)
    @test split(readlines(csv2)[2], ",")[7] == "ERROR"
end
```

- [ ] **Step 2: Chạy để thấy test thất bại**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: FAIL, `run_instance` not defined.

- [ ] **Step 3: Cài đặt** — `orange/src/experiment.jl`:

```julia
const CSV_HEADER = "instance,P,run,n,m,nD,status,z,mlu,mlu_base,improvement,bound,gap,solve_time,nodes,check"

clean(s) = replace(string(s), "," => ";", "\n" => " ")

function run_instance(prefix::AbstractString, name::AbstractString, P::Int, tlimit::Real;
                      runs::Int=10, fast_threshold::Real=120.0, max_vars::Int=3_000_000,
                      outdir::AbstractString="results", r_mode::Symbol=:ecmp,
                      budget=nothing, tag::AbstractString="")
    mkpath(outdir)
    csv = joinpath(outdir, "$(name)-P$(P)$(tag).csv")
    open(csv, "w") do io
        println(io, CSV_HEADER)
        local inst, rs, mlu_base
        try
            inst = read_instance(prefix; budget=budget)
            nvars = length(inst.dem_s) * P * inst.n * (inst.n - 1)
            if nvars > max_vars
                println(io, "$name,$P,0,$(inst.n),$(inst.m),$(length(inst.dem_s)),SKIPPED_TOO_LARGE,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,nvars=$nvars")
                return
            end
            rs = [build_r(inst, p; mode=r_mode) for p in 1:P]
            mlu_base = base_mlu(inst, rs, P)
        catch e
            println(io, "$name,$P,0,NaN,NaN,NaN,ERROR,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,$(clean(sprint(showerror, e)))")
            return
        end
        nD = length(inst.dem_s)
        nruns, run_id = runs, 1
        while run_id <= nruns
            status, zv, mlu, bnd, gap, t, nodes, check = "ERROR", NaN, NaN, NaN, NaN, NaN, NaN, ""
            try
                opt = optimizer_with_attributes(HiGHS.Optimizer, "random_seed" => run_id, "threads" => 1)
                model, x, z = build_model(inst, rs, P, opt; tlimit=tlimit)
                optimize!(model)
                st = termination_status(model)
                status = st == MOI.OPTIMAL ? "Optimal" : st == MOI.INFEASIBLE ? "Infeasible" : "Not Optimal"
                t = solve_time(model)
                nodes = try node_count(model) catch; NaN end
                bnd = try objective_bound(model) catch; NaN end
                if has_values(model)
                    zv = value(z)
                    paths = extract_paths(inst, x, P)
                    chk = check_solution(inst, rs, paths, P, zv; tol=1e-5)
                    mlu = chk.mlu
                    check = chk.budget_ok ? "ok" : "budget_violation"
                    gap = status == "Optimal" ? 0.0 : 1.0 - bnd / objective_value(model)
                    if run_id == 1
                        write_srpaths(inst, paths, P, joinpath(outdir, "$(name)-P$(P)$(tag)-srpaths.json"))
                        write_loads(inst, rs, paths, P, joinpath(outdir, "$(name)-P$(P)$(tag)-loads.csv"))
                    end
                else
                    check = "no_solution"
                end
            catch e
                status, check = "ERROR", clean(sprint(showerror, e))
            end
            impr = isnan(mlu) ? NaN : 1.0 - mlu / mlu_base
            println(io, "$name,$P,$run_id,$(inst.n),$(inst.m),$nD,$status,$zv,$mlu,$mlu_base,$impr,$bnd,$gap,$t,$nodes,$check")
            flush(io)
            # chỉ chạy đủ số lần nếu lần đầu giải nhanh
            run_id == 1 && !(t <= fast_threshold) && (nruns = 1)
            run_id += 1
        end
    end
    return csv
end
```

`orange/scripts/run_experiments.jl`:
```julia
using Orange
# julia --project=orange orange/scripts/run_experiments.jl <P> <tlimit> [first] [last]
P = parse(Int, ARGS[1])
tlimit = parse(Float64, ARGS[2])
first_i = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 1
last_i = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 20
outdir = joinpath(@__DIR__, "..", "results")
for i in first_i:last_i
    name = "setA-" * lpad(i, 2, '0')
    prefix = joinpath(@__DIR__, "..", "..", "project", "setA", name)
    println("== $name P=$P  ", time()); flush(stdout)
    run_instance(prefix, name, P, tlimit; outdir=outdir)
end
```

- [ ] **Step 4: Chạy test và thử một instance**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: PASS.
Run: `julia --project=orange orange/scripts/run_experiments.jl 1 30 1 1`
Expected: tạo `orange/results/setA-01-P1.csv`, `-srpaths.json`, `-loads.csv`; cột `check` là `ok`.

- [ ] **Step 5: Commit**

```bash
git add orange && git commit -m "feat: experiment runner (csv, srpaths, loads, error-tolerant)"
```

---

### Task 7: Chạy thực nghiệm đầy đủ

**Files:**
- Output: `orange/results/*`

- [ ] **Step 1: Ghi môi trường**

```bash
julia --project=orange -e 'using InteractiveUtils; versioninfo(); using Pkg; Pkg.status()' > orange/results/environment.txt
```
Ghi thêm CPU, RAM, hệ điều hành vào cuối file.

- [ ] **Step 2: Chạy $t=0$, 1800 s (bước 6 readme)** — chạy nền

```bash
julia --project=orange orange/scripts/run_experiments.jl 1 1800 > orange/results/log-P1.txt 2>&1
```
Theo dõi `log-P1.txt`. Không chạy tiến trình nặng khác cùng lúc (ảnh hưởng thời gian đo).

- [ ] **Step 3: Kiểm tra kết quả $t=0$**

Với mỗi `setA-XX-P1.csv`: không có `Infeasible` và `ERROR` (nếu có, sửa lỗi rồi chạy lại riêng instance đó); cột `check` là `ok`; `mlu <= mlu_base`. Ghi danh sách instance `SKIPPED_TOO_LARGE` và `Not Optimal`.

- [ ] **Step 4: Chạy $t=0,1$, 3600 s (bước 9 readme)** — chạy nền sau khi Step 2 xong

```bash
julia --project=orange orange/scripts/run_experiments.jl 2 3600 > orange/results/log-P2.txt 2>&1
```

- [ ] **Step 5: Kiểm tra kết quả $t=0,1$** như Step 3, thêm: `check` không được là `budget_violation`.

- [ ] **Step 6: Commit kết quả**

```bash
git add orange/results && git commit -m "data: SetA experiment results"
```

---

### Task 8: Bảng, biểu đồ và báo cáo

**Files:**
- Create: `orange/scripts/make_tables.jl`, `report/report.tex`
- Output: `report/table_P1.tex`, `report/table_P2.tex`

**Interfaces:**
- Consumes: `orange/results/setA-XX-P{1,2}.csv`, `...-loads.csv`, `environment.txt`.

- [ ] **Step 1: Viết `orange/scripts/make_tables.jl`**

```julia
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
    k == length(st) && return "Optimal"
    k == 0 && return join(unique(st), "/")
    return "Optimal $k/$(length(st))"
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
        g(k) = avg([num(r, k) for r in rows])
        println(io, join([name, r1["n"], r1["m"], r1["nD"], fmt(num(r1, "mlu_base")), fmt(g("mlu")),
                          fmt(100 * g("improvement"); d=1), fmt(g("solve_time"); d=1), status_summary(rows),
                          fmt(g("gap")), fmt(g("nodes"); d=0), string(length(rows))], " & "), " \\\\")
    end
    println(io, "\\hline\n\\end{tabular}")
    return String(take!(io))
end
for P in (1, 2)
    write(joinpath(@__DIR__, "..", "..", "report", "table_P$P.tex"), table(P))
end
```
Run: `julia --project=orange orange/scripts/make_tables.jl`
Expected: `report/table_P1.tex` và `table_P2.tex` có một dòng cho mỗi instance đã chạy.

- [ ] **Step 2: Viết `report/report.tex`**

```latex
\documentclass[11pt,a4paper]{article}
\usepackage[margin=2cm]{geometry}
\usepackage{amsmath,amssymb,booktabs,graphicx,pgfplots,hyperref}
\pgfplotsset{compat=1.18}
\title{Adaptive Segment Routing (Challenge EURO/ROADEF 2026): a MILP approach}
\author{}
\begin{document}
\maketitle
\section{Introduction}            % bối cảnh Orange/SR, động cơ, mô tả T-ASR (BAI_TOAN_FINAL mục 1-2)
\section{Mathematical model}
\subsection{Data}                 % bảng tham số; r theo ECMP và lý do (ví dụ toy, so với calculating_r.pdf)
\subsection{Variables}
\subsection{Objective}            % min MLU + eps*sum x, nói rõ là xấp xỉ của lex-min (5)
\subsection{Constraints}          % (1)-(4), tuyến tính hoá (4), cấm đoạn không tới được
\section{Numerical experiments}
\subsection{Instances}            % bảng quy mô, budget, multigraph flag, metric thực
\subsection{Environment}          % environment.txt, HiGHS threads=1, mip_rel_gap mặc định
\subsection{Results at period 0 (1800 s)}
\begin{table}[h]\centering\scriptsize\input{table_P1}\caption{Period 0}\end{table}
\subsection{Results at periods 0 and 1 (3600 s)}
\begin{table}[h]\centering\scriptsize\input{table_P2}\caption{Periods 0 and 1}\end{table}
\begin{figure}[h]\centering
\begin{tikzpicture}\begin{axis}[width=0.9\linewidth,height=5cm,xlabel={rank},ylabel={link load},legend pos=north east]
\addplot+[mark=none] table[x=rank,y=base,col sep=comma]{../orange/results/setA-01-P1-loads.csv};
\addplot+[mark=none] table[x=rank,y=opt,col sep=comma]{../orange/results/setA-01-P1-loads.csv};
\legend{shortest paths, optimized}
\end{axis}\end{tikzpicture}
\caption{Sorted link loads, setA-01, period 0}\end{figure}
\subsection{Deviations from the instructions}  % xem danh sách ở Step 3
\section{Conclusion}
\end{document}
```

- [ ] **Step 3: Viết nội dung, gồm mục "Deviations from the instructions"**

Bắt buộc nêu rõ (kèm lý do):
1. Không dùng notebook Pluto v2 để đọc dữ liệu: nó từ chối `multigraph=true` ở 10/20 instance, dù không có cung song song.
2. Cách tính $r$ (ECMP từng chặng hay đếm đường, theo câu trả lời của thầy), kèm ví dụ toy $0{,}5$ so với $2/3$.
3. Mục tiêu min MLU (+ $\varepsilon\sum x$) thay cho lex-min (5).
4. Số lần chạy theo chính sách (cột Runs) và các instance `SKIPPED_TOO_LARGE`.
5. Thời gian đo là `solve_time` với 1 luồng.

- [ ] **Step 4: Biên dịch**

Run: `cd report && pdflatex report.tex && pdflatex report.tex`
Expected: PDF ≤ 10 trang; bảng và biểu đồ hiển thị đúng.

- [ ] **Step 5: Commit**

```bash
git add report orange/scripts/make_tables.jl && git commit -m "docs: report, result tables and load chart"
```

---

## Các task tùy chọn (chỉ làm khi Task 0–8 đã xong hoặc đang chờ thực nghiệm)

### Task 9 (tùy chọn): Độ nhạy theo ngân sách

**Files:**
- Create: `orange/scripts/budget_sensitivity.jl`

**Interfaces:**
- Consumes: `run_instance(...; budget, tag)`.
- Produces: `results/setA-0X-P2-B<β>.csv`; một bảng "MLU theo $\beta$" trong báo cáo.

- [ ] **Step 1: Viết script**

```julia
using Orange
outdir = joinpath(@__DIR__, "..", "results")
for name in ("setA-01", "setA-02"), b in (0, 1, 5, 20, Inf)
    prefix = joinpath(@__DIR__, "..", "..", "project", "setA", name)
    run_instance(prefix, name, 2, 600; runs=1, budget=b, tag="-B$(b)", outdir=outdir)
end
```

- [ ] **Step 2: Chạy và kiểm tra**

Run: `julia --project=orange orange/scripts/budget_sensitivity.jl`
Expected: MLU (cột `mlu`) không tăng khi $\beta$ tăng (với các lần Optimal). Nếu tăng, kiểm tra lại ràng buộc (4).

- [ ] **Step 3: Đưa vào báo cáo** một bảng nhỏ $\beta$ → MLU cho hai instance, rồi commit.

```bash
git add orange && git commit -m "exp: budget sensitivity"
```

### Task 10 (tùy chọn): So sánh ECMP và đếm đường

**Files:**
- Create: `orange/scripts/compare_r_modes.jl`

**Interfaces:**
- Consumes: `build_r(...; mode)`, `build_model`, `extract_paths`, `max_utilization`, `base_mlu`.

- [ ] **Step 1: Viết script**

```julia
using Orange, JuMP, HiGHS
println("instance,pairs,pairs_diff,max_abs_diff,mlu0_ecmp,mlu0_pc,mlu_ecmp,mlu_pc,mlu_pc_under_ecmp")
for i in 1:4
    name = "setA-" * lpad(i, 2, '0')
    inst = read_instance(joinpath(@__DIR__, "..", "..", "project", "setA", name))
    rE = build_r(inst, 1); rP = build_r(inst, 1; mode=:pathcount)
    diffs = [maximum(abs(get(Dict(rE[k]), a, 0.0) - get(Dict(rP[k]), a, 0.0))
                     for a in union(first.(rE[k]), first.(rP[k]))) for k in keys(rE)]
    opt = optimizer_with_attributes(HiGHS.Optimizer, "threads" => 1)
    res = Dict{Symbol,Any}()
    for (tag, r) in ((:E, rE), (:P, rP))
        model, x, z = build_model(inst, [r], 1, opt; tlimit=600)
        optimize!(model)
        res[tag] = (mlu=value(z), paths=extract_paths(inst, x, 1))
    end
    # nghiệm tối ưu theo đếm đường, nhưng mạng thật chạy ECMP
    cross = max_utilization(inst, [rE], res[:P].paths, 1)
    println(join([name, length(diffs), count(>(1e-9), diffs), maximum(diffs),
                  base_mlu(inst, [rE], 1), base_mlu(inst, [rP], 1), res[:E].mlu, res[:P].mlu, cross], ","))
end
```

- [ ] **Step 2: Chạy và ghi kết quả**

Run: `julia --project=orange orange/scripts/compare_r_modes.jl > orange/results/compare_r_modes.csv`
Expected: `max_abs_diff > 0` ở ít nhất một instance có đường ngắn nhất bằng nhau; cột `mlu_pc_under_ecmp` cho thấy sai lệch khi dùng sai mô hình $r$.

- [ ] **Step 3: Commit**

```bash
git add orange && git commit -m "exp: compare ECMP and path-count split coefficients"
```

### Task 11 (tùy chọn): Heuristic tìm kiếm cục bộ cho instance lớn

**Files:**
- Modify: `orange/src/heuristic.jl` (thay toàn bộ)
- Test: `orange/test/runtests.jl`

**Interfaces:**
- Consumes: `direct_paths`, `changes`, `max_utilization`.
- Produces: `local_search(inst, rs, P; time_limit=600.0, cand_per_move=50, seed=1) -> (paths, mlu)`. Chỉ xét đi thẳng hoặc đúng **1 waypoint** (ghi rõ trong báo cáo); luôn tôn trọng ngân sách.

- [ ] **Step 1: Viết test thất bại**

```julia
@testset "local search" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, p) for p in 1:2]
    paths, mlu = local_search(inst, rs, 1; time_limit=5.0)
    @test mlu <= base_mlu(inst, rs, 1) + 1e-12
    @test mlu >= brute_best(inst, 1) - 1e-9
    @test mlu ≈ max_utilization(inst, rs, paths, 1)
    inst0 = read_instance(TOY; maxseg=2, budget=0)
    paths0, _ = local_search(inst0, rs, 2; time_limit=5.0)
    @test all(d -> paths0[(d, 1)] == paths0[(d, 2)], 1:2)
end
```

- [ ] **Step 2: Chạy để thấy test thất bại**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: FAIL, `local_search` not defined.

- [ ] **Step 3: Cài đặt** — `orange/src/heuristic.jl`:

```julia
segs(seq) = zip(seq, seq[2:end])

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
        improved = false
        for d in shuffle(rng, users)
            s, t = inst.dem_s[d], inst.dem_t[d]
            cands = shuffle(rng, [w for w in 0:inst.n if w == 0 || (w != s && w != t)])
            for w in cands[1:min(end, cand_per_move)]
                new = w == 0 ? [s, t] : [s, w, t]
                old = paths[(d, bp)]
                new == old && continue
                all(seg -> haskey(rs[bp], seg), segs(new)) || continue
                # ngân sách: ảnh hưởng tới thời kỳ bp (so với bp-1) và bp+1 (so với bp)
                delta = Dict{Int,Float64}()
                bp >= 2 && (delta[bp] = changes(paths[(d, bp-1)], new) - changes(paths[(d, bp-1)], old))
                bp < P && (delta[bp+1] = changes(new, paths[(d, bp+1)]) - changes(old, paths[(d, bp+1)]))
                all(q -> used[q] + delta[q] <= inst.budget[q], keys(delta)) || continue
                apply!(d, bp, old, -1.0); apply!(d, bp, new, 1.0)
                val = current()
                if val < best - 1e-12
                    paths[(d, bp)] = new
                    for (q, dq) in delta; used[q] += dq; end
                    best, improved = val, true
                    break
                end
                apply!(d, bp, new, -1.0); apply!(d, bp, old, 1.0)
            end
            improved && break
        end
        improved || break                                  # cực tiểu địa phương
    end
    return paths, max_utilization(inst, rs, paths, P)
end
```

- [ ] **Step 4: Chạy để thấy test đạt**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: PASS.

- [ ] **Step 5: Chạy cho các instance MILP không giải được** (`SKIPPED_TOO_LARGE` hoặc gap lớn), 600 s mỗi instance; ghi MLU heuristic, MLU ban đầu và % cải thiện vào một bảng riêng trong báo cáo. Commit:

```bash
git add orange && git commit -m "feat: local search heuristic for large instances"
```

### Task 12 (tùy chọn): Mục tiêu lexicographic hai bước

**Files:**
- Modify: `orange/src/model.jl` (thêm hàm)
- Test: `orange/test/runtests.jl`

**Interfaces:**
- Consumes: `(model, x, z, load)` của `build_model` đã giải.
- Produces: `lex_second_stage!(model, z, load, inst, zstar)` — giữ $z \le z^\*$, tối thiểu tổng tải (xấp xỉ bước thứ hai của lex-min).

- [ ] **Step 1: Viết test**

```julia
@testset "lex second stage keeps MLU" begin
    inst = read_instance(TOY; maxseg=2)
    rs = [build_r(inst, 1)]
    model, x, z, load = build_model(inst, rs, 1, OPT)
    optimize!(model)
    zstar = value(z)
    total1 = sum(value(load[1][a]) / inst.cap[a] for a in 1:inst.m)
    lex_second_stage!(model, z, load, inst, zstar)
    optimize!(model)
    @test value(z) <= zstar + 1e-6
    @test sum(value(load[1][a]) / inst.cap[a] for a in 1:inst.m) <= total1 + 1e-6
end
```

- [ ] **Step 2: Cài đặt** (thêm vào cuối `orange/src/model.jl`)

```julia
function lex_second_stage!(model, z, load, inst::Instance, zstar::Real)
    @constraint(model, z <= zstar * (1 + 1e-6) + 1e-9)
    @objective(model, Min, sum(load[p][a] / inst.cap[a] for p in eachindex(load), a in 1:inst.m
                               if !(a in inst.down[p])))
    return model
end
```

- [ ] **Step 3: Chạy test, rồi commit**

Run: `julia --project=orange orange/test/runtests.jl`
Expected: PASS.
```bash
git add orange && git commit -m "feat: lexicographic second stage"
```

---

## Self-Review

**Spec coverage** (readme và `BAI_TOAN_FINAL.md`):

| Yêu cầu | Task |
|---|---|
| Bước 2: đồ thị G(0) từ JSON (thay Pluto, có giải thích) | 1, 8 (Deviations) |
| Bước 3: $r$ (cả ECMP và `calculating_r.pdf`) | 2 |
| Bước 4: Data ($r$, $c$, $v(d,0)$, maxSeg) | 1, 2 |
| Bước 5–6: mô hình $t=0$, 1800 s, bảng đủ cột | 3, 6, 7, 8 |
| Bước 7–9: $t=1$, ngân sách, 3600 s | 2, 3, 4, 5, 7, 8 |
| Báo cáo ≤ 10 trang, 3 phần, môi trường, trung bình nhiều lần, node B&B | 6, 7, 8 |
| Câu hỏi còn mở (r, bước 9, số lần chạy, mục tiêu, gap) | 0 |

**Các lỗi của bản kế hoạch trước đã sửa:** chu trình rời (mục tiêu $+\varepsilon\sum x$, BFS trong `extract_paths`, kiểm tra $\le z$); một lỗi làm dừng cả lô (try/catch, `status=ERROR`); CPU time (`threads=1`, không chạy song song khi đo); gap khi không có nghiệm (NaN) và status tóm tắt nhiều lần chạy.

**Type consistency:** `build_model` trả `(model, x, z, load)` (các test lấy 3 phần tử đầu); `rs` luôn là vector theo thời kỳ; `paths[(d,p)]`; `check_solution` trả `(mlu, budget_ok)`; `run_instance` trả đường dẫn CSV.

**Review Focus:** năm mục ở đầu đều có test: #1 Task 3 `extract_paths ignores cycles` và Task 5; #2 Task 3 `unreachable segments`; #3 Task 2 `ecmp float ties`; #4 Task 4 `budget 0`; #5 Task 6 `runner ... survives errors`.

**Rủi ro còn lại:** HiGHS có thể chậm trên instance vừa (khi đó báo cáo Not Optimal kèm gap, đúng yêu cầu); `max_vars=3·10⁶` có thể vẫn quá lớn với RAM của máy (giảm nếu Task 7 bị hết bộ nhớ).

---

## Nhật ký quyết định

| Ngày | Câu hỏi | Quyết định | Nguồn |
|---|---|---|---|
| 19/10 | Cách tính $r$ | **Chốt: ECMP từng chặng** làm chính (khớp đề và Bảng 2); đếm đường chỉ để so sánh (Task 10) | Thầy không trả lời; tự quyết theo tài liệu |
| 19/10 | Ý nghĩa bước 9 | **Chốt: giải chung $t=0,1$** (readme bước 8) | Thầy không trả lời; tự quyết theo tài liệu |
| 19/10 | Số lần chạy | **Chốt: 10 lần nếu lần đầu ≤ 120 s, ngược lại 3 lần** (trước đây 1 lần) | readme yêu cầu 10 lần, quỹ thời gian không đủ |
| 19/10 | Mục tiêu | **Chốt: min MLU + $\varepsilon\sum x$** | readme chỉ yêu cầu một giá trị mục tiêu |
| 19/10 | Solver | HiGHS, 1 luồng, `mip_rel_gap=1e-6` | Mặc định |
| 19/10 | Công thức gap | **Chốt: $1-\mathrm{LB}/\mathrm{UB}$** | readme ghi rõ |
| 19/10 | Instance quá lớn cho MILP | **Chốt: ghi "too large" và bổ sung heuristic** (Task 11); `max_vars` giữ $3\cdot10^6$ theo phép đo bộ nhớ (Task 5 Step 3) | Tự quyết theo tài liệu |
