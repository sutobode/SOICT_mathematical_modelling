# Hướng dẫn đọc thư mục kết quả (`orange/results/`)

Thư mục này chứa **mọi số liệu thực nghiệm** của dự án Orange (T-ASR). Dành cho người viết báo cáo.

## 1. Hai bảng chính thức theo yêu cầu của thầy (dùng trực tiếp trong báo cáo)

| File | Nội dung |
|---|---|
| `table_official_P1.md` / `.csv` | **Bảng 1** (bước 6 của readme): chỉ thời kỳ 0, giới hạn 1800 s |
| `table_official_P2.md` / `.csv` | **Bảng 2** (bước 9): thời kỳ 0 và 1 có ngân sách, giới hạn 3600 s |

Cột: số đỉnh, số cung, số demand, giá trị tốt nhất (MLU), CPU time của `optimize!` (trung bình các lần chạy), status, gap $=1-\mathrm{LB}/\mathrm{UB}$ nếu không tối ưu, số nút B&B (trung bình), số lần chạy, mô hình, và giá trị tốt nhất biết được bằng mọi phương pháp.

- Dòng `arc-pc`: mô hình theo cung của đề, hệ số $r$ theo `calculating_r.pdf`. Chỉ có cho instance 01–05 (các instance lớn hơn không dựng được trong RAM).
- Dòng có dấu `*`: nghiệm của mô hình waypoint (bài toán hạn chế: tối đa một waypoint mỗi demand), status và gap tính cho bài toán hạn chế đó. Nghiệm vẫn hợp lệ cho bài toán gốc.
- Số lần chạy: 10 nếu lần đầu giải trong 120 s, còn lại 3 lần (xem cột Runs). Lệch yêu cầu "10 lần" ở instance chậm cần nêu trong báo cáo.

Tạo lại bảng: `julia orange/scripts/best_known.jl` rồi `julia orange/scripts/official_tables.jl`.

## 2. Số liệu gốc từng lần chạy

Quy ước tên: `setA-XX-P{P}{tag}.csv`, trong đó `P=1` là chỉ thời kỳ 0, `P=2` là thời kỳ 0 và 1.

| Mẫu tên | Nội dung |
|---|---|
| `setA-XX-P{P}.csv` | mô hình theo cung của đề, $r$ theo ECMP |
| `setA-XX-P{P}-pc.csv` | mô hình theo cung của đề, $r$ theo công thức của thầy (**bảng chính thức**) |
| `setA-XX-wp-P{P}.csv` | mô hình waypoint, ứng viên theo độ vòng |
| `setA-XX-wp-P{P}-cg.csv` | mô hình waypoint với sinh cột |
| `setA-XX-wp-P{P}-cg-lns.csv` | sinh cột và LNS (tinh chỉnh) |
| `setA-XX-wp-P{P}-cg-pc.csv` | như `-cg` với $r$ của thầy (chỉ setA-18 và 20) |
| `*-srpaths.json` | nghiệm đúng định dạng đề (`d`, `t` từ 0; `w` là id nút) |
| `*-loads.csv` | vector tải đã sắp giảm dần (trước/sau tối ưu), dùng vẽ biểu đồ |

Cột CSV theo cung: `instance, P, run, n, m, nD, status, z, mlu, mlu_base, improvement, bound, gap, solve_time, nodes, check, obj, start_time, start_mlu`.
Cột CSV waypoint: `instance, P, K, n, m, nD, binaries, status, mlu, mlu_base, improvement, bound, gap, solve_time, nodes, check, obj, heur_mlu, heur_time, cg_lp, cg_iters, cg_time, lns_mlu, lns_time`.
`mlu_base` là MLU khi mọi demand đi thẳng theo đường ngắn nhất; `improvement = 1 − mlu/mlu_base`. `check=ok` nghĩa là nghiệm đã được tính lại độc lập.

## 3. Phân tích và kiểm chứng

| File | Nội dung |
|---|---|
| `best_known.csv` | nghiệm tốt nhất từng (instance, P) từ mọi nguồn, kèm cận dưới (`lb_orig` cho bài toán gốc maxSeg = 6, `lb_1wp` cho bài toán một waypoint) và gap |
| `verification.csv` | kiểm tra độc lập bằng Python (tính lại MLU, ngân sách, maxSeg từ file srpaths) |
| `r_difference.csv` | so sánh $r$ theo ECMP và theo công thức của thầy trên cả 20 instance: giống nhau ở 18/20, mỗi instance 18 và 20 chỉ lệch 1 cặp nút |
| `compare_r_modes.csv` | (nếu có) so sánh MLU theo hai cách tính $r$ |
| `environment.txt` | phiên bản Julia, gói, CPU, RAM, hệ điều hành (mục "môi trường chạy" của báo cáo) |
| `watchdog.log` | các lần bộ giám sát RAM dừng tiến trình (nếu có) |
| `STATUS.md`, `log-*.txt` | trạng thái và log chạy |

## 3b. Truy vết (để thầy kiểm tra lại)

| File | Nội dung |
|---|---|
| `MANIFEST.md` | commit mã nguồn, môi trường, tham số solver, chính sách số lần chạy, **các lệnh đã chạy** và cách kiểm tra lại một kết quả |
| `MANIFEST.csv` | mỗi file kết quả: kích thước, SHA-256, thời điểm ghi, commit mã nguồn gần nhất trước đó |
| `MANIFEST_INPUTS.csv` | SHA-256 của dữ liệu đầu vào `project/setA/*.json` |

Tạo lại: `python -I orange/scripts/make_manifest.py` (cũng tự chạy mỗi lần sao lưu zip).

## 4. Những điều cần ghi trung thực trong báo cáo

1. Mô hình theo cung của đề chỉ chạy được cho instance 01–05 (06–20 cần từ 5 triệu đến gần 1 tỷ biến, vượt RAM).
2. Hệ số $r$: công thức của thầy và ECMP trùng ở 18/20 instance (xem `r_difference.csv`).
3. Số lần chạy 10 chỉ cho instance nhanh; instance chậm chạy 3 lần.
4. Mục tiêu là min MLU (xấp xỉ mức đầu của thứ tự từ điển); đã thêm bước tinh chỉnh từ điển trong code nhưng bảng chính thức dùng MLU.
5. Không dùng chính notebook Pluto (đồ thị dựng ra giống hệt).
6. CPU time là thời gian chạy thực (wall-clock) của `optimize!` với HiGHS một luồng.
7. Gap `lb_1wp` chỉ là cận dưới của bài toán hạn chế một waypoint, không phải của bài toán gốc.

Chi tiết đầy đủ: `orange/README.md` (mục 5e đối chiếu yêu cầu của thầy), `project/BAI_TOAN_FINAL.md`.
