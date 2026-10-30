# T-ASR: Time-dependent Adaptive Segment Routing

Cài đặt Julia/JuMP và bộ thực nghiệm cho bài toán **T-ASR** của Challenge **EURO/ROADEF 2026 "Keep The Flow!"** (Orange). Bài tập lớn môn Mô hình hoá toán học, SOICT.

Với mỗi nhu cầu lưu lượng, chọn dãy waypoint (segment routing) trên hai thời kỳ $t=0,1$, sao cho **tải lớn nhất trên các cung (MLU) nhỏ nhất**, trong giới hạn số đoạn và **ngân sách** thay đổi đường giữa hai thời kỳ.

> README này mô tả nhánh `main`. Nhánh `feature/tasr` còn có một số hàm chưa có trên `main` (xem [mục 14](#14-nhánh-và-thành-viên)).

## Mục lục

1. [Tổng quan](#1-tổng-quan)
2. [Bài toán](#2-bài-toán)
3. [Phương pháp](#3-phương-pháp)
4. [Yêu cầu và cài đặt](#4-yêu-cầu-và-cài-đặt)
5. [Bắt đầu nhanh](#5-bắt-đầu-nhanh)
6. [Hướng dẫn sử dụng](#6-hướng-dẫn-sử-dụng)
7. [Kết quả](#7-kết-quả)
8. [Khả năng tái lập và truy vết](#8-khả-năng-tái-lập-và-truy-vết)
9. [Kiểm thử và kiểm chứng](#9-kiểm-thử-và-kiểm-chứng)
10. [Cấu trúc kho](#10-cấu-trúc-kho)
11. [Tài liệu](#11-tài-liệu)
12. [Quyết định thiết kế](#12-quyết-định-thiết-kế)
13. [Giới hạn đã biết](#13-giới-hạn-đã-biết)
14. [Nhánh và thành viên](#14-nhánh-và-thành-viên)
15. [Xử lý sự cố](#15-xử-lý-sự-cố)
16. [Nguồn](#16-nguồn)

## 1. Tổng quan

| | |
|---|---|
| Ngôn ngữ, solver | Julia 1.13, JuMP, HiGHS (1 luồng) |
| Dữ liệu | SetA: 20 instance, từ 20 đến 400 nút, từ 20 đến 6000 nhu cầu (`project/setA/`) |
| Kết quả chính thức | 12 cấu hình, mỗi cấu hình 10 lần chạy, đã kiểm chứng độc lập (đợt chạy trên server) |
| Kết quả mở rộng | Hai bảng 20 instance theo yêu cầu của thầy (nhiều dòng là cận trên, 1 lần chạy) |
| Chất lượng | Test khớp vét cạn, kiểm chứng độc lập bằng Python, nhật ký truy vết, kiểm toán thực nghiệm |

Tính năng chính:
- Mô hình MILP theo cung **đúng đề** (giải chính xác instance nhỏ, có gap thật).
- Mô hình **waypoint** dạng chọn phương án, **sinh cột**, **LNS** cho instance lớn.
- Hệ số tách luồng $r$ theo công thức đếm đường (`calculating_r.pdf`) và ECMP từng bước.
- Tối ưu từ điển chính xác cho vector tải (`exact_lexicographic_loads!`).
- Hỗ trợ cung song song (nhiều cung cùng cặp đầu mút).
- Bộ chạy chính thức: 10 lần, chặn thời gian bằng callback, kiểm chứng độc lập.

## 2. Bài toán

- Mạng có hướng $G=(V,A)$: mỗi cung $a$ có dung lượng $c(a)$ và metric $\omega(a)$.
- Nhu cầu $d=(s,\tau,\nu_t)$ đi từ $s$ đến $\tau$ với lưu lượng $\nu_t$ ở thời kỳ $t$.
- **Segment routing:** đường là dãy $s\to w_1\to\dots\to\tau$ gồm tối đa `maxSeg` đoạn (SetA: 6). Mỗi đoạn đi theo đường ngắn nhất; tải tách lên cung $a$ theo hệ số $r(i,j,a)$.
- **Ngân sách:** số đoạn khác nhau giữa đường ở $t=0$ và $t=1$ không vượt $\kappa(1)$.
- **Mục tiêu:** cực tiểu từ điển vector tải sắp giảm $\{\lambda(a,t)\}$. Bảng kết quả dùng **min MLU** $z=\max_{a,t}\lambda(a,t)$ (chính thức: MLU thuần; bảng mở rộng có thêm phạt $\varepsilon\sum x$ rất nhỏ để phá hoà).

$$\min\ z\quad\text{s.t.}\quad \text{bảo toàn luồng},\ \ \sum x\le\text{maxSeg},\ \ \sum_{d,(i,j)}r(i,j,a)\,\nu^d_t\,x^{dt}_{ij}\le c(a)\,z,\ \ \sum\lvert x^{t}-x^{t-1}\rvert\le\kappa(t).$$

Định nghĩa đầy đủ từng ký hiệu và công thức: [project/DINH_NGHIA_BAI_TOAN_VA_YEU_CAU_THAY.md](project/DINH_NGHIA_BAI_TOAN_VA_YEU_CAU_THAY.md). Hình minh hoạ: [project/HINH_DUNG_BAI_TOAN.md](project/HINH_DUNG_BAI_TOAN.md).

## 3. Phương pháp

| Thành phần | Mô tả | File |
|---|---|---|
| Đọc dữ liệu | đọc 3 file JSON thành `Instance`; từ chối khuyên (self loop) | `orange/src/io.jl` |
| Hệ số $r$ | `:pathcount` ($\sigma_{iu}\sigma_{vj}/\sigma_{ij}$, theo `calculating_r.pdf`) và `:ecmp` (chia đều từng bước); Dijkstra trên đồ thị chiếu, cung song song giữ riêng | `orange/src/ecmp.jl` |
| MILP theo cung | mô hình đúng đề; ràng buộc bậc; MTZ khi cần chặn chu trình | `orange/src/model.jl` |
| Tối ưu từ điển | `exact_lexicographic_loads!` (công thức sắp xếp bằng biến nhị phân, cố định từng hạng), `total_load_second_stage!` | `orange/src/model.jl` |
| Mô hình waypoint | mỗi nhu cầu chọn một phương án (đi thẳng hoặc 1 waypoint); ngân sách dạng gọn | `orange/src/wpmodel.jl` |
| Sinh cột | định giá waypoint bằng chi phí rút gọn; cận dưới hợp lệ khi $P=1$ | `orange/src/wpmodel.jl` (`colgen`) |
| Tinh chỉnh theo tải | `load_freezing_refine`: đóng băng cung chạm đỉnh rồi hạ mức kế tiếp (không phải tối ưu từ điển chính xác) | `orange/src/wpmodel.jl` |
| Heuristic | leo đồi: đổi waypoint của nhu cầu qua cung tắc nhất; mỗi bước thử đổi riêng thời kỳ tắc nhất, rồi đổi cùng lúc mọi thời kỳ | `orange/src/heuristic.jl` |
| LNS | cố định phần lớn nhu cầu, giải lại một nhóm gần cung nghẽn | `orange/src/lns.jl` |
| Kiểm chứng | tính lại tải và ngân sách từ đường đã chọn; kiểm tra nghiệm từ điển; ghi và đọc `srpaths` | `orange/src/verify.jl` |
| Báo cáo chính thức | gộp các lần chạy, nhãn trạng thái, cận dưới thuần MLU | `orange/src/reporting.jl`, `orange/scripts/official_common.jl` |
| Bộ chạy | seed, 10 lần, chặn thời gian bằng callback, ghi CSV và bằng chứng | `orange/src/experiment.jl` |

**Chiến lược theo cỡ instance:**

| Instance | Cách giải | Kết quả |
|---|---|---|
| setA-01 đến 05 | MILP theo cung, khởi tạo bằng heuristic | nghiệm theo đề, gap thật |
| Instance lớn hơn | sinh cột, MILP waypoint, LNS (mô hình theo cung quá lớn) | **cận trên** (nhãn `(1-wp)` hoặc "Restricted feasible upper bound") |

Giải thích thuật toán: [dễ hiểu](project/SEMINAR_THUAT_TOAN_DE_HIEU.md), [kỹ thuật](project/SEMINAR_THUAT_TOAN_SUTOBODE.md), [theo từng module](project/SEMINAR_GOI_JULIA_ORANGE.md).

## 4. Yêu cầu và cài đặt

| Yêu cầu | Phiên bản |
|---|---|
| Julia | 1.13 (đã kiểm tra trên 1.13.1) |
| Python | 3.x, chỉ thư viện chuẩn (kiểm chứng, vận hành); hình dùng thêm matplotlib |
| LaTeX | `pdflatex`, chỉ khi biên dịch báo cáo trong `report/` |

```bash
git clone https://github.com/sutobode/SOICT_mathematical_modelling.git
cd SOICT_mathematical_modelling
julia --project=orange -e 'using Pkg; Pkg.instantiate()'
```

Phụ thuộc Julia (khai báo trong `orange/Project.toml`, khoá phiên bản trong `Manifest.toml`): JuMP, HiGHS, Graphs, JSON3, SHA.

## 5. Bắt đầu nhanh

```bash
julia --project=orange orange/test/runtests.jl
```

Dùng như thư viện:

```julia
using Orange, JuMP, HiGHS
inst = read_instance("project/setA/setA-01")
rs = [build_r(inst, p; mode=:pathcount) for p in 1:inst.P]   # r cho t=0 và t=1 trên G_t
model, x, z = build_model(inst, rs, 2, HiGHS.Optimizer; tlimit=600)
optimize!(model)
paths = extract_paths(inst, x, 2)            # (demand, kỳ) => [nguồn, waypoint..., đích]
check_solution(inst, rs, paths, 2, value(z)) # MLU và ngân sách tính lại độc lập
```

## 6. Hướng dẫn sử dụng

### 6.1. Chạy thực nghiệm chính thức

Chế độ chính thức luôn dùng hệ số đếm đường và MLU thuần; giới hạn thời gian phải là **1800 s** (`P=1`) hoặc **3600 s** (`P=2`), trừ khi hậu tố tên có chữ `smoke`.

```bash
# Mô hình theo cung: <P> <giới hạn giây> [instance đầu] [instance cuối] [lần đầu] [lần cuối] [hậu tố]
julia --project=orange orange/scripts/run_experiments.jl 1 1800 1 5     # t=0
julia --project=orange orange/scripts/run_experiments.jl 2 3600 1 5     # t=0,1 có ngân sách

# Mô hình waypoint (nghiệm hạn chế = cận trên): <P> <giới hạn giây> [đầu] [cuối] [lần đầu] [lần cuối] [max_binaries]
julia --project=orange orange/scripts/run_official_wp.jl 1 1800 10 10
julia --project=orange orange/scripts/run_official_wp.jl 2 3600 7 7

# Biến thể khám phá
julia --project=orange orange/scripts/run_wp.jl 1 1800                  # waypoint, mọi instance
julia --project=orange orange/scripts/run_heuristic.jl 1 600            # chỉ heuristic
julia --project=orange orange/scripts/run_lex_pathcount.jl project/setA/setA-01 1 1800 out.json   # tối ưu từ điển chính xác
```

### 6.2. Tạo bảng và kiểm chứng

```bash
julia --project=orange orange/scripts/official_tables.jl       # bảng chính thức (nhãn INCOMPLETE cho dòng chưa đủ 10 lần)
python -I orange/scripts/verify_srpaths.py                     # kiểm chứng độc lập các nghiệm đã lưu
python orange/scripts/check_multigraph.py                      # SetA có cung song song hay không
```

### 6.3. Đầu ra (`orange/results/`)

| File | Nội dung |
|---|---|
| `setA-XX-*.csv` | kết quả từng lần chạy (một dòng mỗi lần) |
| `*-srpaths.json` | nghiệm theo định dạng của đề (`d`, `t` từ 0; `w` là id nút) |
| `solverlogs/` | log HiGHS của các lần chạy |
| `table_official_P{1,2}.{md,csv}`, `best_known.csv` | bảng và nghiệm tốt nhất |
| `RUN_JOURNAL.md`, `MANIFEST.md`, `verification.csv` | nhật ký, SHA-256 từng file, kết quả kiểm chứng |

Với đợt chính thức, tên cột của từng lần chạy nằm ở đầu `report/final_run_level_results.csv`. Nhãn trạng thái của bảng chính thức: `Optimal`, `Feasible - not proven optimal`, `Restricted feasible upper bound`. Thời gian `solve_time` là thời gian của `optimize!` (HiGHS 1 luồng). Cột `check` là `ok` hoặc `budget_violation`, có thể kèm hậu tố như `(budget-truncated)` khi HiGHS vượt hạn và kết quả được báo tại giới hạn.

Chi tiết mọi tuỳ chọn: [orange/README.md](orange/README.md).

## 7. Kết quả

### 7.1. Đợt chạy chính thức (server, 10 lần mỗi cấu hình, đã kiểm chứng)

Chỉ các cấu hình đủ lần 1 đến 10 mới được báo cáo. Đầy đủ: `report/final_configuration_summary.csv`, `report/final_run_level_results.csv` (120 lần chạy), bảng sinh bởi `official_tables.jl` trong `report/experiment_evidence/evidence/generated_official_tables/`.

| Instance | $t$ | Mô hình | MLU tốt nhất | Cận dưới | Thời gian TB (s) | Trạng thái |
|---|---|---|---|---|---|---|
| setA-01 | 0 | theo cung | 0,92938 | 0,92938 | 0,7 | Optimal (10/10) |
| setA-02 | 0 | theo cung | 0,54858 | 0,54858 | 3,7 | Optimal (10/10) |
| setA-03 | 0 | theo cung | 0,94354 | 0,94354 | 32,0 | Optimal (10/10) |
| setA-04 | 0 | theo cung | 0,51828 | 0,45907 | 1800,3 | Feasible, chưa chứng minh tối ưu (gap TB 0,203) |
| setA-05 | 0 | theo cung | 0,11552 | 0,11552 | 149,4 | Optimal (10/10) |
| setA-10 | 0 | waypoint hạn chế | 0,07120 | không áp dụng | 1801,2 | cận trên của bài toán gốc |
| setA-01 | 0,1 | theo cung | 0,92938 | 0,92938 | 20,8 | Optimal (10/10) |
| setA-02 | 0,1 | theo cung | 0,90307 | 0,90307 | 2234,9 | Optimal (chứng minh trong 4/10 lần) |
| setA-03 | 0,1 | theo cung | 0,94354 | 0,94354 | 759,6 | Optimal (10/10) |
| setA-04 | 0,1 | theo cung | 0,58857 | 0,58114 | 3600,7 | Feasible, chưa chứng minh tối ưu (gap 0,0126) |
| setA-05 | 0,1 | theo cung | 0,20499 | 0,20499 | 1880,3 | Optimal (chứng minh trong 5/10 lần) |
| setA-07 | 0,1 | waypoint hạn chế | 0,90799 | không áp dụng | 80,8 | cận trên của bài toán gốc |

Hai cấu hình cuối mỗi nhóm là mô hình **hạn chế** (tối đa 1 waypoint, `maxSeg`=6), chỉ cho cận trên. Số liệu setA-05 ở $t=0,1$ nhận được sau khi sửa `local_search` (thử đổi cùng lúc mọi thời kỳ), chạy lại ngày 24/10.

### 7.2. Hai bảng mở rộng cho 20 instance

[Bảng 1](orange/results/table_official_P1.md) ($t=0$, 1800 s) và [Bảng 2](orange/results/table_official_P2.md) ($t=0,1$, 3600 s) trong `orange/results/` đủ 20 dòng theo các cột của thầy (n, m, $|D|$, best objective, CPU time, status, gap, B&B nodes). Đây là đợt chạy của `sutobode`; số liệu khác đợt chính thức ở mục 7.1 (ví dụ setA-04 ở $t=0$: 0,50105 so với 0,51828). Các dòng instance lớn là `(1-wp)`, chỉ **1 lần chạy**.

| Nhóm ($t=0$) | Instance | Ghi chú |
|---|---|---|
| Theo cung, tối ưu | 01, 02, 03, 05 | ví dụ setA-05: 0,11552 |
| Theo cung, chưa tối ưu | 04 (gap 0,19) | arc 0,50105; waypoint tìm được 0,45912 |
| Waypoint `(1-wp)`, tối ưu bài toán hạn chế | 06, 07, 08, 09, 11, 12, 15, 16, 17, 18, 20 | cận trên của bài toán gốc |
| Waypoint `(1-wp)`, chưa tối ưu | 10, 13, 14, 19 | gap 0,001 đến 0,027 |

> **Nhãn `(1-wp)`:** chỉ cho tối đa 1 waypoint trong khi `maxSeg`=6, nên giá trị là cận trên hợp lệ của bài toán gốc; trạng thái và gap chỉ nói về bài toán hạn chế.

**Mốc so sánh** `mlu_base` là MLU khi mọi nhu cầu đi thẳng (không waypoint). Ví dụ setA-05 ở $t=0$: 0,3333 xuống 0,1155 (giảm 65%).

Báo cáo kết quả: [project/BAO_CAO_KET_QUA_THUC_NGHIEM.md](project/BAO_CAO_KET_QUA_THUC_NGHIEM.md), `report/experiment_audit.md`, `report/setA05_P2_supplementary_analysis.md`.

## 8. Khả năng tái lập và truy vết

- **Solver:** HiGHS, `threads=1`, `mip_rel_gap=1e-6`, `random_seed` bằng số thứ tự lần chạy.
- **Chặn thời gian:** bản chính thức đo thời gian bằng đồng hồ đơn điệu, callback HiGHS ghi nghiệm và cận dưới tại giới hạn; nếu HiGHS vượt hạn quá 10 s ở pha không gọi callback thì báo trạng thái tại giới hạn (`ok(budget-truncated)`), các lần chạy lại có ghi `*-budget.json` làm bằng chứng.
- **Số lần chạy:** 10 lần (seed 1 đến 10) cho mỗi cấu hình chính thức.
- **Truy vết:** `report/experiment_audit.md` ghi phiên bản mã, hai bản vá kèm SHA-256 (`fix_time_limit_status.patch`, `fix_local_search_joint.patch`), thời gian chạy và các dòng bị thay thế (lưu trong `superseded_*`, không xoá). `orange/results/MANIFEST.md` ghi SHA-256 và lệnh sinh từng file của đợt chạy mở rộng; `RUN_JOURNAL.md` ghi sự cố và quyết định.
- **Thư mục kết quả các đợt chạy:** `server_results_2026-10-21/`, `server_results_2026-10-22/`, `server_results_2026-10-24/`, `server_results_2026-10-24_v4/`, `improvement_results_2026-10-24/`, `BAO_CAO_KET_QUA_2026-10-24/`.
- **Nghiệm lưu lại:** mọi lần chạy lưu `srpaths.json`; giá trị trong bảng là MLU **tính lại từ đường đã chọn**, không lấy từ biến của solver.

## 9. Kiểm thử và kiểm chứng

```bash
julia --project=orange orange/test/runtests.jl
```

Bộ test gồm 59 nhóm `@testset` trong `runtests.jl` cùng `lexicographic.jl` và `official_reporting.jl` (kiểm toán ghi 72/72 nhóm đạt trước hai đợt chạy lại).

| Nhóm | Nội dung |
|---|---|
| Khớp ví dụ của đề | $r$ khớp Bảng 2 của đề (ECMP và đếm đường); toy: MLU 0,3125 / 0,4375 / 0,3750 |
| Khớp vét cạn | mô hình trên ví dụ toy |
| Cung song song | các nhóm test `parallel arcs ...` |
| Tối ưu từ điển | `orange/test/lexicographic.jl` |
| Báo cáo chính thức | `orange/test/official_reporting.jl` |
| SetA không có cung song song | `orange/test/multigraph.jl` và `check_multigraph.py` (`runtests.jl` không `include` file này) |

**Kiểm chứng độc lập:** `orange/scripts/verify_srpaths.py` cài lại bằng Python (chỉ thư viện chuẩn) từ dữ liệu gốc, không dùng chung code với Julia. Kết quả cho 120 lần chạy chính thức nằm ở `report/experiment_evidence/evidence/verify_all_runs.csv`.

## 10. Cấu trúc kho

```
orange/
  src/        gói Julia: io, ecmp, model, wpmodel, heuristic, lns, verify, reporting, experiment
  test/       runtests.jl, lexicographic.jl, official_reporting.jl, multigraph.jl, ví dụ toy
  scripts/    thực nghiệm (Julia), kiểm chứng và vận hành (Python, PowerShell, bash), vẽ hình
  results/    CSV, srpaths.json, bảng, nhật ký, manifest của đợt chạy mở rộng
report/       báo cáo LaTeX (report.tex, sections/), CSV tổng hợp, bằng chứng thực nghiệm
project/      đề bài, dữ liệu SetA (setA/), tài liệu phân tích
server_results_*/, improvement_results_*/, BAO_CAO_KET_QUA_*/   kết quả và báo cáo các đợt chạy
lecture1_v2.pdf, lecture2/ ... lecture6/   tài liệu môn học
```

## 11. Tài liệu

| Mục đích | File trong `project/` |
|---|---|
| Đề bài và yêu cầu | `readme` (của thầy), `calculating_r.pdf`, `DINH_NGHIA_BAI_TOAN_VA_YEU_CAU_THAY.md`, `BAI_TOAN_FINAL.md` |
| Hình minh hoạ | `HINH_DUNG_BAI_TOAN.md`, `figures/` |
| Kế hoạch và phân việc | `PHAN_TICH_YEU_CAU_VA_PHAN_VIEC.md`, `KE_HOACH_CAC_GIAI_DOAN.md`, `PHAN_CONG_NHOM.md` |
| Kết quả và cải tiến | `BAO_CAO_KET_QUA_THUC_NGHIEM.md`, `DE_XUAT_CAI_TIEN_TOI_UU.md` |
| Đối chiếu | `DOI_CHIEU_AUDIT.md`, `NHAN_XET_NHANH_HUNG.md` |
| Đóng góp thành viên | `THONG_KE_DONG_GOP_GIT.md` |
| Thuyết trình | `SEMINAR_PHAN_VIEC_SUTOBODE.md`, `SEMINAR_GOI_JULIA_ORANGE.md`, `SEMINAR_THUAT_TOAN_SUTOBODE.md`, `SEMINAR_THUAT_TOAN_DE_HIEU.md` |
| Kiểm toán thực nghiệm | `report/experiment_audit.md` |

## 12. Quyết định thiết kế

Các điểm đề bài hoặc thầy chưa làm rõ; thầy không trả lời nên nhóm tự chốt:

| Quyết định | Lý do |
|---|---|
| Kết quả chính thức dùng $r$ theo `calculating_r.pdf` | hai tài liệu mâu thuẫn; trùng ở 18/20 instance, lệch ở setA-18 và setA-20 (một cặp nút) |
| Bước 9 giải chung $t=0$ và $t=1$ | readme bước 8: thêm $t=1$ và ngân sách |
| Mục tiêu min MLU | readme chỉ yêu cầu một giá trị "Optimal or Best objective" |
| Chu trình rời: ràng buộc bậc, MTZ khi vi phạm ngân sách | chu trình rời có thể làm ngân sách bị tính thiếu |
| Tắt presolve khi trên 1,2 triệu biến | presolve của HiGHS không tôn trọng giới hạn thời gian |
| Bỏ qua mô hình theo cung khi trên số biến cho phép (`SKIPPED_TOO_LARGE`) | mô hình quá lớn, dùng mô hình waypoint |
| Gắn nhãn dòng waypoint là cận trên | tối đa 1 waypoint trong khi `maxSeg`=6 |
| Bỏ qua cờ `multigraph` trong JSON | SetA không có cung song song; code vẫn hỗ trợ cung song song |

## 13. Giới hạn đã biết

- Các dòng `(1-wp)` và "Restricted feasible upper bound" là **cận trên**, không phải tối ưu của bài toán gốc.
- Đợt chính thức chỉ phủ 12 cấu hình; các dòng còn lại của hai bảng mở rộng chỉ có 1 lần chạy hoặc chưa đủ 10 lần.
- setA-04 chưa chứng minh tối ưu ở cả hai thời kỳ; setA-02 và setA-05 ở $t=0,1$ chỉ chứng minh tối ưu trong 4/10 và 5/10 lần.
- Cận dưới từ sinh cột chỉ chặt cho $P=1$; ở bảng mở rộng Bảng 2 dùng cận dưới của $t=0$ nên gap yếu.
- Tối ưu từ điển chính xác (`exact_lexicographic_loads!`) có test nhưng các bảng đều báo cáo min MLU.
- Số liệu hai đợt chạy (mục 7.1 và 7.2) không hoàn toàn trùng; số chính thức là mục 7.1.

## 14. Nhánh và thành viên

| Nhánh | Nội dung |
|---|---|
| `main` | bản chính: mã của `sutobode`, `hung`, `kien` đã gộp; đợt chạy chính thức và báo cáo |
| `feature/tasr` | phát triển của `sutobode`; còn có `lex_topk!` (tối ưu từ điển chính xác theo tổng tích luỹ) và `lex_refine`, **chưa có trên `main`** |
| `hung` | Nguyễn Quốc Hùng: tối ưu từ điển chính xác, quy trình báo cáo chính thức, hỗ trợ cung song song |
| `kien` | Trung Kiên: đợt chạy server, thí nghiệm cải tiến, sửa `local_search`, setA-05 ở $t=0,1$ |

| Thành viên | Đóng góp chính |
|---|---|
| `sutobode` | gói Julia nền tảng (đọc dữ liệu, $r$, MILP, waypoint, sinh cột, LNS, heuristic, kiểm chứng), bộ test, chiến dịch 20 instance, vận hành và truy vết, tài liệu |
| Nguyễn Quốc Hùng | tối ưu từ điển chính xác, `reporting.jl`, script chính thức có resume, cung song song |
| Trung Kiên | đưa kết quả đợt chạy server (120 lần chạy) vào kho, bổ đề "hai đường khác nhau lệch ≥ 3 segment" và mô hình gộp biến, giải tối ưu setA-05 ở $t=0,1$, sửa `local_search`, báo cáo tổng hợp |

Số liệu commit và dòng code theo git: [project/THONG_KE_DONG_GOP_GIT.md](project/THONG_KE_DONG_GOP_GIT.md). Git chỉ ghi tên tài khoản; phần lớn commit của `sutobode` được làm với sự hỗ trợ của Claude theo yêu cầu của chủ kho.

## 15. Xử lý sự cố

| Triệu chứng | Nguyên nhân và cách xử lý |
|---|---|
| `SKIPPED_TOO_LARGE` | mô hình theo cung quá lớn; dùng `run_official_wp.jl` hoặc `run_wp.jl` |
| `optimize!` chạy quá giới hạn thời gian | HiGHS đôi khi vượt hạn; bản chính thức có chặn bằng callback (`ok(budget-truncated)`) và đã tắt presolve cho mô hình lớn |
| `check` là `budget_violation` | chu trình rời làm ngân sách sai; runner tự giải lại với MTZ |
| Lỗi "official P=… experiments require tlimit=…" | chế độ chính thức chỉ chấp nhận 1800 s (`P=1`) và 3600 s (`P=2`); dùng hậu tố có chữ `smoke` cho lần thử ngắn |

## 16. Nguồn

- **Đề bài và dữ liệu:** Challenge EURO/ROADEF 2026 "Keep The Flow!" do Orange đề xuất (`Challenge_Orange_ROADEF_2026_Subject.pdf` ở thư mục gốc); dữ liệu SetA, tài liệu môn học và `calculating_r.pdf` do giảng viên cung cấp.
- **Mã nguồn trong `orange/`:** bài làm của nhóm cho mục đích học tập.
