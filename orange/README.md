# Orange T-ASR — mã nguồn Julia

Cài đặt mô hình MILP cho bài toán **T-Adaptive Segment Routing** (Challenge EURO/ROADEF 2026, Orange) cùng các công cụ chạy thực nghiệm trên SetA. Phân tích bài toán nằm ở [`../project/BAI_TOAN_FINAL.md`](../project/BAI_TOAN_FINAL.md), kế hoạch và tiến độ ở [`../project/KE_HOACH_THUC_HIEN.md`](../project/KE_HOACH_THUC_HIEN.md).

## 1. Yêu cầu và cài đặt

- Julia 1.13 (đã kiểm tra trên 1.13.1), Windows 11. Báo cáo cần LaTeX (MiKTeX có sẵn `pdflatex`).
- Thư viện: JuMP, HiGHS, Graphs, JSON3 (đã khai báo trong `Project.toml`).

```bash
cd SOICT_mathematical_modelling
julia --project=orange -e 'using Pkg; Pkg.instantiate()'
```

## 2. Chạy kiểm thử

```bash
julia --project=orange orange/test/runtests.jl
```
Bộ test mất khoảng 30 giây và gồm: đọc dữ liệu của cả 20 instance; hệ số tách $r$ khớp Bảng 2 của đề (cả ECMP lẫn đếm đường); tải và MLU của ví dụ toy (0.3125, 0.4375, 0.3750); mô hình MILP khớp vét cạn trên toy cho $t=0$, $t=0,1$ và ngân sách 0; các tình huống biên (demand lưu lượng 0, đoạn không tới được, chu trình trong nghiệm, metric thực); runner; heuristic.

## 3. Chạy thực nghiệm

```bash
# MILP: <P> <giới hạn giây> [instance đầu] [instance cuối]
julia --project=orange orange/scripts/run_experiments.jl 1 1800      # chỉ t=0 (bước 6 của readme)
julia --project=orange orange/scripts/run_experiments.jl 1 1800 1 20 pc   # như trên với r theo công thức của calculating_r.pdf (kết quả hậu tố -pc)
julia --project=orange orange/scripts/run_experiments.jl 2 3600      # t=0 và t=1, có ngân sách (bước 9)
julia --project=orange orange/scripts/run_experiments.jl 2 3600 4 5  # chỉ instance 04 và 05

# Mô hình waypoint (chạy được cho nhiều instance hơn nhiều): <P> <giây> [đầu] [cuối] [max_binaries]
julia --project=orange orange/scripts/run_wp.jl 1 1800
julia --project=orange orange/scripts/run_wp.jl 2 3600

# Heuristic cho cả 20 instance: <P> <giây> [đầu] [cuối]
julia --project=orange orange/scripts/run_heuristic.jl 1 600
julia --project=orange orange/scripts/run_heuristic.jl 2 600

# Phân tích phụ (chạy sau khi thực nghiệm chính xong)
julia --project=orange orange/scripts/budget_sensitivity.jl            # MLU theo ngân sách β (setA-01, 02)
julia --project=orange orange/scripts/compare_r_modes.jl > orange/results/compare_r_modes.csv   # ECMP so với đếm đường

# Bảng LaTeX cho báo cáo, rồi biên dịch
julia --project=orange orange/scripts/make_tables.jl
cd report && pdflatex report.tex && pdflatex report.tex
```
**Lưu ý:** trong lúc chạy thực nghiệm chính, đừng chạy việc nặng khác (thời gian giải là số liệu nộp) và đừng đóng máy hay để máy ngủ.

### Kết quả sinh ra (`orange/results/`)

| File | Nội dung |
|---|---|
| `setA-XX-P{1,2}.csv` | một dòng mỗi lần chạy, các cột bên dưới |
| `setA-XX-P{1,2}-srpaths.json` | nghiệm lần chạy đầu, đúng định dạng `srpaths` của đề (`d`, `t` từ 0; `w` là id nút) |
| `setA-XX-P{1,2}-loads.csv` | tải đã sắp giảm dần, trước (`base`) và sau (`opt`) khi tối ưu, dùng vẽ biểu đồ |
| `setA-XX-wp-P{1,2}[-cg].csv` (+ `-srpaths.json`, `-loads.csv`) | kết quả mô hình waypoint (`-cg`: ứng viên do sinh cột chọn), cột: `instance, P, K, n, m, nD, binaries, status, mlu, mlu_base, improvement, bound, gap, solve_time, nodes, check, obj, heur_mlu, heur_time, cg_lp, cg_iters, cg_time` |
| `log-P{1,2}.txt`, `log-wp-P{1,2}.txt` | log chạy |
| `environment.txt` | phiên bản Julia, gói, CPU, RAM |

Các cột của CSV: `instance, P, run, n, m, nD, status, z, mlu, mlu_base, improvement, bound, gap, solve_time, nodes, check, obj, start_time, start_mlu`.

- `status`: `Optimal`, `Not Optimal`, `Infeasible` (không nên xảy ra), `SKIPPED_TOO_LARGE` hoặc `ERROR`.
- `mlu_base`: MLU khi mọi demand đi thẳng theo đường ngắn nhất. `improvement = 1 − mlu/mlu_base`.
- `gap`: $1 − \mathrm{bound}/\mathrm{obj}$, luôn là gap thật (kể cả khi Optimal). `obj` là giá trị hàm mục tiêu có thêm phạt $\varepsilon\sum x$.
- `solve_time`: thời gian của `optimize!` (wall-clock, HiGHS 1 luồng). `start_time`, `start_mlu`: thời gian và MLU của nghiệm heuristic dùng khởi tạo (không tính vào `solve_time`).
- `check`: `ok` nếu MLU và ngân sách tính lại độc lập khớp. `ok(acyclic)` nghĩa là đã phải giải lại với ràng buộc MTZ. Dòng có `check` khác `ok` bị `make_tables.jl` loại khỏi giá trị trung bình và đánh dấu trong bảng.

## 4. Cấu trúc mã nguồn

| File | Vai trò | Hàm chính |
|---|---|---|
| `src/io.jl` | đọc 3 file JSON | `read_instance(prefix; maxseg, budget)` → `Instance` (thời kỳ $p = t+1$) |
| `src/ecmp.jl` | hệ số tách $r$ | `routing`, `ecmp_split`, `pathcount_split`, `build_r(inst, p; mode=:ecmp)` |
| `src/verify.jl` | kiểm tra độc lập | `utilization`, `max_utilization`, `base_mlu`, `changes`, `check_solution`, `write_srpaths`, `write_loads` |
| `src/model.jl` | mô hình JuMP | `build_model`, `extract_paths`, `lex_second_stage!` |
| `src/wpmodel.jl` | MILP chọn waypoint theo đường, sinh cột, tinh chỉnh từ điển | `candidates`, `build_wp_model(...; K, K2)`, `extract_wp_paths`, `colgen`, `lex_refine` |
| `src/experiment.jl` | chạy và ghi CSV | `run_instance` (mô hình theo cung), `run_wp_instance` (mô hình waypoint) |
| `src/heuristic.jl` | tìm kiếm cục bộ | `local_search` |

Ví dụ dùng trực tiếp:
```julia
using Orange, JuMP, HiGHS
inst = read_instance("project/setA/setA-01")
rs = [build_r(inst, p) for p in 1:inst.P]            # r cho t=0 và t=1 (trên G_t)
model, x, z = build_model(inst, rs, 2, HiGHS.Optimizer; tlimit=600)
optimize!(model)
paths = extract_paths(inst, x, 2)                    # (demand, kỳ) => [nguồn, waypoint..., đích]
check_solution(inst, rs, paths, 2, value(z))
```

## 5. Mô hình và các quyết định thiết kế

Mô hình đúng theo đề: biến nhị phân $x^{dt}_{ij}$, ràng buộc bảo toàn luồng (1), số đoạn (2), tải (3) và ngân sách (4) (tuyến tính hóa bằng biến phụ $y$). Các lựa chọn không có sẵn trong đề, kèm lý do:

| Quyết định | Lý do |
|---|---|
| **$r$ theo ECMP từng chặng** (mặc định), có thêm `mode=:pathcount` | Đề định nghĩa ECMP và Bảng 2 của đề khớp ECMP ($r=0{,}5$); công thức đếm đường của `calculating_r.pdf` cho $2/3$ trên cùng cung. Cả hai đều được cài đặt và có test. |
| **Giải chung $t=0$ và $t=1$** ở bước 9 | readme bước 8: "extend the model to include the time period 1 with the addition of the Budget constraints". Dòng "only time period 0" ở bước 9 được coi là lỗi đánh máy. |
| **Mục tiêu min MLU** $+\ \varepsilon\sum x$, $\varepsilon = 10^{-7}/\lvert D\rvert$ | readme chỉ yêu cầu báo một "Optimal or Best objective value". Lexicographic đầy đủ không báo được bằng một số; giai đoạn hai có sẵn (`lex_second_stage!`) nhưng không dùng trong bảng. |
| **Đoạn không tới được trong $G_t$ bị cố định bằng 0** | nếu không, mô hình "dịch chuyển tức thời" miễn phí. |
| **Chặn chu trình trong nghiệm** | ràng buộc (1) cho phép "đường + chu trình"; khi ngân sách hữu hạn, chu trình có thể lách ngân sách. Có ràng buộc bậc ≤ 1 ở mọi nút; nếu nghiệm vẫn vi phạm ngân sách thì runner giải lại với MTZ (`acyclic=true`). |
| **So sánh khoảng cách có dung sai** $10^{-9}$ | instance 05, 08, 12, 14 có metric thực. |
| **Bỏ qua cờ `multigraph` trong JSON** | 10/20 instance khai `true` nhưng không có cung song song; notebook Pluto v2 từ chối chúng nên không dùng. |
| **MILP khởi tạo bằng nghiệm heuristic** (≤ 1 waypoint) | không có điểm khởi tạo tốt thì HiGHS rất chậm (ví dụ setA-02 với $t=0,1$ sau 120 s không cải thiện gì). Thời gian heuristic (tối đa 30 s) được ghi riêng. |
| **HiGHS 1 luồng, `mip_rel_gap = 1e-6`** | để `solve_time` xấp xỉ CPU time và gap báo cáo có ý nghĩa. |
| **Số lần chạy:** 10 nếu lần đầu giải trong 120 s, còn lại 3 lần | readme yêu cầu 10 lần, nhưng 10 lần × 1 giờ × nhiều instance vượt quỹ thời gian còn lại. Cột số lần chạy được ghi trong bảng. |

## 5b. Mô hình waypoint (thuật toán mở rộng, `src/wpmodel.jl`)

Mô hình theo cung ở mục 5 có $\lvert D\rvert\,n(n-1)$ biến nhị phân mỗi thời kỳ nên chỉ chạy được cho setA-01 đến 05, và cận dưới LP rất yếu. Mô hình waypoint thay thế biến cung bằng **biến chọn phương án**: với mỗi demand $d$ và thời kỳ $t$, chọn đúng một phương án trong $W_d$ = {không waypoint} $\cup$ {một waypoint $w\in C_d$} $\cup$ {cặp $(w_1,w_2)$ lấy từ $K_2$ ứng viên đầu}.

- **Tải:** phương án $c$ đóng góp $r(\text{đoạn},a,t)\,\delta(d,t)$ trên từng đoạn của đường $s\to w\to\tau$; ràng buộc $\text{tải}(a)\le c(a)\,z$ như cũ.
- **Ngân sách:** $\sum_d\sum_{\text{đoạn}}\lvert g_t-g_{t-1}\rvert\le\beta(t)$ với $g$ là chỉ báo (0/1) đoạn đó nằm trong đường được chọn; đây chính là định nghĩa `dist` của đề.
- **Ứng viên $C_d$:** $K$ nút có độ vòng $D[s,w]+D[w,\tau]-D[s,\tau]$ nhỏ nhất và có đường ở mọi thời kỳ. Với $K=n-2$ (mọi nút) và $K_2=0$ mô hình là **chính xác** cho bài toán gốc khi $\text{maxSeg}=2$ (đã kiểm chứng bằng vét cạn trên toy với ngân sách 0, 3, 20 và $P=1,2$); với $K_2=n-2$ là chính xác khi $\text{maxSeg}=3$. Với $\text{maxSeg}$ lớn hơn (SetA có $\text{maxSeg}=6$) nghiệm là **cận trên** của bài toán gốc.
- **Khởi tạo:** nghiệm heuristic được thêm vào tập phương án nếu hợp lệ ở mọi thời kỳ.
- **Kích thước:** $\lvert D\rvert\cdot P\cdot\lvert W_d\rvert$ biến (ví dụ setA-06: 49 500 biến thay vì 4,95 triệu). `run_wp_instance` chọn $K$ lớn nhất sao cho số biến không vượt `max_binaries` (mặc định $1{,}5\cdot10^6$).
- **Chất lượng đo được** ($t=0$, $K=n-2$, một waypoint, HiGHS 1 luồng): giải tối ưu trong vài giây cho setA-01 đến 09; ví dụ setA-06: MLU 0,0986 (heuristic: 0,2676); setA-05 với $t=0,1$: 0,205 (heuristic bị kẹt ở 1,0).

## 5c. Sinh cột (`colgen`) và tinh chỉnh từ điển (`lex_refine`)

**Sinh cột cho mô hình waypoint.** Thay vì lấy $K$ ứng viên theo độ vòng, bắt đầu từ ít ứng viên ($K_0=3$) rồi lặp: giải LP của mô hình thu gọn, lấy đối ngẫu $\lambda_{a,t}\ge0$ của ràng buộc tải và $\mu_{d,t}$ của ràng buộc gán, định giá mọi waypoint $w$ của mỗi demand bằng chi phí rút gọn

$$\mathrm{rc}(d,w)=\varepsilon+\min_t\Big[\delta(d,t)\big(g_t(s,w)+g_t(w,\tau)\big)-\mu_{d,t}\Big],\qquad g_t(u,v)=\sum_a\lambda_{a,t}\,r(u,v,a,t),$$

và thêm các $w$ có $\mathrm{rc}<0$. Chi phí định giá mỗi vòng là $O(n^2\cdot\text{độ dài }FG+\lvert D\rvert n)$ nhờ nhớ $g_t(u,v)$. Khi hội tụ:
- với $P=1$, giá trị LP cuối là **cận dưới hợp lệ** của bài toán một waypoint (cột `cg_lp`); với $P>1$ ngân sách không được đưa vào bước định giá nên chỉ dùng để chọn ứng viên (`cg_lp` = NaN);
- **làm giàu**: thêm `extra` (mặc định 10) cột có chi phí rút gọn thấp nhất cho mỗi demand, vì nghiệm nguyên cần những cột mà nghiệm LP không dùng (ví dụ setA-06: LP 0,0986 nhưng MILP chỉ trên cột LP được 0,1014).
Mô hình cuối chỉ có vài trăm đến vài nghìn biến thay vì hàng chục nghìn. Chạy: `run_wp.jl <P> <giây> <đầu> <cuối> 1500000 cg` (kết quả có hậu tố `-cg`).

**Tinh chỉnh từ điển** (`lex_refine`, mục tiêu (5) của đề): sau khi giải min MLU, "đóng băng" các cung đang chạm mức tối đa, giải lại để tối thiểu MLU trên các cung còn lại, lặp tối đa `levels` mức. Luôn trả về nghiệm không tệ hơn nghiệm đầu vào theo thứ tự từ điển (có test). Đây là heuristic cho thứ tự từ điển (đóng băng mọi cung chạm mức tối đa, không chỉ những cung buộc phải ở mức đó).

## 5d. Vận hành an toàn (RAM và luồng)

Các lần chạy dài trên máy dùng chung nên có các biện pháp sau:
- **Một luồng:** HiGHS chạy `threads=1`; chạy script với `JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1`.
- **Ưu tiên thấp:** hạ độ ưu tiên tiến trình thực nghiệm để máy không bị đơ: PowerShell `(Get-Process -Id <PID>).PriorityClass = 'BelowNormal'`.
- **Số tiến trình nặng đồng thời tối đa 2 đến 3.** Đã đo: tiến trình mô hình theo cung cho setA-04/05 dùng 2 đến 3 GB, mô hình waypoint đầy đủ cho instance lớn có thể dùng nhiều hơn.
- **Bảo vệ trong thuật toán:** `run_wp_instance` giảm $K$ cho vừa 50% RAM trống (`choose_K`; ước lượng khoảng $200\cdot\text{độ dài }FG+800$ byte mỗi biến nhị phân) và ghi `SKIPPED_LOW_MEMORY` nếu ngay cả $K=0$ không vừa; ngưỡng `max_vars` của mô hình theo cung ngăn dựng mô hình quá lớn.
- **Máy ngủ làm đóng băng mọi thứ:** ngày 19/10, Windows vào Modern Standby 18:40–19:10 (nhật ký `Kernel-Power`), mọi tiến trình thực nghiệm, hẹn giờ và sao lưu đều dừng. Chạy `powershell -NoProfile -ExecutionPolicy Bypass -File orange\scripts\keep_awake.ps1` để giữ máy thức (yêu cầu `ES_SYSTEM_REQUIRED`, không đổi cài đặt nguồn); gập nắp laptop vẫn có thể làm máy ngủ nên hãy cắm sạc, mở nắp hoặc đặt "When I close the lid" = Do nothing. Thời gian `solve_time` đo bằng đồng hồ thực nên một lần chạy bị cắt ngang bởi giấc ngủ sẽ có thời gian lớn bất thường: loại bỏ hoặc chạy lại lần đó.
- **Giám sát RAM:** `scripts/watchdog.ps1` dừng tiến trình Julia tốn RAM nhất khi RAM trống dưới 1,5 GB (trừ các PID trong `results/watch_exclude.txt`, ví dụ Julia của IDE) và ghi `results/watchdog.log`:
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File orange\scripts\watchdog.ps1 -MinFreeGB 1.5 -IntervalSec 15
  ```
  Nếu watchdog đã dừng một tiến trình, dòng tương ứng trong CSV sẽ thiếu hoặc dừng giữa chừng; chạy lại instance đó.

## 5e. Đối chiếu với yêu cầu của thầy (`project/readme`)

| Yêu cầu | Cách đáp ứng | Mức độ |
|---|---|---|
| Bước 2: dựng đồ thị $G$ ở $t=0$ bằng script Pluto | `read_instance` đọc cùng 3 file JSON và tạo cùng đồ thị (cùng ánh xạ id, cung, metric, capacity). Không dùng chính notebook vì notebook v2 từ chối `multigraph=true` (10/20 file khai như vậy dù **không** có cung song song). | tương đương, không giống từng chữ |
| Bước 3: tính $r$ theo `calculating_r.pdf` | Có cả hai: `build_r(inst, p; mode=:pathcount)` là công thức của thầy ($\sigma_{iu}\sigma_{vj}/\sigma_{ij}$ khi $d_{iu}+c_a+d_{vj}=d_{ij}$), `mode=:ecmp` (mặc định) là định nghĩa của đề. **Đã đo trên cả 20 instance** (`scripts/r_difference.jl`, `results/r_difference.csv`): hai cách cho **cùng hệ số trên 18/20 instance**; setA-18 và setA-20 mỗi instance chỉ có **1 cặp nút** (trên 89 700 và 159 600 cặp) lệch nhau (độ lệch 0,167). Hai cách chỉ khác nhau khi có đường ngắn nhất bằng nhau, và SetA hầu như không có. Vì vậy kết quả ECMP vẫn đúng theo công thức của thầy cho 18 instance; hai instance còn lại được chạy riêng với `-pc`. | đáp ứng |
| Bước 4: phần Data ($r$, $c$, $v$, MaxSeg) | `read_instance` + `build_r` | đáp ứng |
| Bước 5–6: mô hình $t=0$ không có ngân sách; SetA; 1800 s; bảng gồm số đỉnh, cung, demand, giá trị, CPU time của `optimize!`, status, gap, (số nút B&B) | `run_experiments.jl <P=1> 1800` ghi đủ các cột trong CSV | đáp ứng cho instance **01–05** |
| Bước 7–9: thêm $t=1$, ngân sách; 3600 s | `run_experiments.jl <P=2> 3600` | đáp ứng cho instance **01–05** |
| Trung bình 10 lần chạy | 10 lần nếu lần đầu giải trong 120 s, ngược lại 3 lần (cột `run` trong CSV) | một phần |
| Môi trường chạy | `results/environment.txt` | đáp ứng |

**Phần không phủ được bằng mô hình theo đề:** instance 06–20 cần từ 5 triệu đến gần 1 tỷ biến nhị phân và không dựng nổi trong RAM của máy (ghi `SKIPPED_TOO_LARGE`). Với các instance này, nghiệm đến từ mô hình waypoint (mục 5b, 5c), là bài toán *hạn chế* (một waypoint mỗi demand); nghiệm vẫn hợp lệ cho bài toán gốc và đã được kiểm chứng độc lập (`scripts/verify_srpaths.py`). Trên các instance giải được cả hai cách (01–05) nghiệm waypoint trùng hoặc gần trùng tối ưu của mô hình theo đề (setA-05 trùng đến 8 chữ số; setA-04 cách cận dưới của bài toán gốc 0,011%).

## 5f. Theo dõi tiến độ khi đang chạy

- **Trang trạng thái:** `orange/results/STATUS.md` (mở trong VS Code, tự tải lại khi file đổi). Trang gồm giờ, RAM trống, các tiến trình Julia (PID, giờ bắt đầu, RAM, CPU), dòng cuối của từng log, bảng kết quả theo từng file CSV (số lần chạy, trạng thái, MLU tốt nhất, thời gian trung bình, gap, số phút kể từ lần ghi cuối) và các lần watchdog đã can thiệp.
- **Tạo hoặc làm mới:** `python -I orange/scripts/status.py` (một lần) hoặc `python -I orange/scripts/status.py --loop 60 --hours 24` (mỗi 60 giây).
- **Log chi tiết:** `orange/results/log-*.txt`; mỗi dòng `== setA-XX ...` là lúc một instance bắt đầu. Một instance chậm không ghi gì cho đến khi xong lần chạy đầu, nên nếu `log` đứng yên thì xem cột "Cập nhật" trong STATUS và CPU của tiến trình: CPU vẫn tăng nghĩa là đang chạy.
- **Số lần chạy đã xong của một instance:** đếm số dòng trong `setA-XX-P{1,2}[-pc].csv` (mỗi lần chạy một dòng).
- **Dừng khẩn cấp một chuỗi:** `Stop-Process -Id <PID>` (PowerShell); kết quả của các instance đã xong vẫn còn trong CSV.

## 6. Giới hạn đã biết

- **Mô hình theo cung chỉ chạy được cho instance 01–05** (xem mục 5b cho mô hình waypoint chạy được nhiều hơn). Số biến là $\lvert D\rvert\,n(n-1)$ mỗi thời kỳ: từ 15 nghìn (setA-01) đến 958 triệu (setA-20); ngưỡng `max_vars = 3·10⁶`. Đo thực tế: dựng mô hình của setA-05 (990 nghìn biến) cần 3,8 GiB, nên setA-06 cần khoảng 19 GiB. Các instance còn lại ghi `SKIPPED_TOO_LARGE`, được bù bằng heuristic (một waypoint, không đảm bảo tối ưu).
- **Gap có thể rất lớn** khi hết giờ: nới lỏng LP của mô hình yếu, nên cận dưới thường bằng 0 ở instance vừa (ví dụ setA-02 với $t=0,1$ sau 120 s).
- **Thời gian đo là wall-clock** (với 1 luồng gần bằng CPU time).
- **Heuristic** dừng khi cung tải lớn nhất không cải thiện được, kể cả khi nhiều cung cùng mức tải; chỉ xét tối đa một waypoint mỗi demand.
- Các lỗi nhỏ đã biết và hoãn: xem sổ `.superpowers/sdd/KE_HOACH_THUC_HIEN/progress.md` (không nằm trong git).

## 7. Kiểm tra độc lập

Mọi nghiệm được trích thành dãy waypoint rồi tính lại tải bằng `utilization` (không dùng biến của solver) và so với $z$; ngân sách được tính lại bằng `changes`. File `srpaths.json` có thể được kiểm tra bằng bộ kiểm tra của đề nếu có.
