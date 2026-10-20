# Nhận xét nhánh `hung` (Nguyễn Quốc Hùng) — việc cần sửa trước khi merge

**Người nhận:** Hùng (tác giả nhánh `hung`).
**Phiên bản đã xem:** `origin/hung` @ `3ad9544` (hai commit 20/10: `0d627df` 15:35 và `3ad9544` 16:47), xây trên `main` @ `e054989`.
**Người nhận xét:** M1, ngày 20/10/2026 ~19:30. Mọi mục đều ghi rõ **đã chạy thật** hay **đọc code**.

> **Tóm tắt một dòng:** hướng đi đúng và chạy được ở đường chính (đã thử), nhưng **chưa dùng được** vì (1) bảng bỏ hết số liệu đã chạy, (2) nhãn trạng thái sai cho mô hình đầy đủ, (3) hàng thu hẹp thiếu sinh cột và LNS, (4) tối ưu từ điển không chạy nổi kể cả với instance nhỏ nhất, (5) xung đột với `main`.

---

## 1. Những điểm tốt (giữ nguyên)

| Điểm | Bằng chứng |
|---|---|
| Bộ test của nhánh đạt toàn bộ | **Đã chạy:** `julia --project=orange orange/test/runtests.jl` → mã thoát 0, mọi `Test Summary` đều Pass |
| Chế độ `official` ép $r$ theo `calculating_r.pdf`, mục tiêu MLU thuần, đúng giới hạn 1800 s / 3600 s | **Đã chạy:** `run_experiments.jl 1 1800 1 1 ecmp` bị từ chối (mã thoát 1); giới hạn sai chỉ cho phép với hậu tố `-smoke` |
| Đường chính chạy đúng, đủ 10 lần, có nghiệm và file tải cho từng lần, kiểm chứng độc lập | **Đã chạy:** setA-01, $t=0$: 10 lần Optimal (0,929384), bảng ra `setA-01 … full_arc … 10/10 … Optimal … verified` |
| `check_solution` kiểm tra thêm `maxSeg` | **Đọc code** (`verify.jl`) |
| Cận dưới chỉ lấy khi mục tiêu thuần MLU (`pure_mlu_bound`), gap không giả 0 | **Đọc code** + test |
| Đổi tên `lex_refine` → `load_freezing_refine` (trung thực: đây không phải tối ưu từ điển) | **Đọc code** |
| Chỉ nhận mẫu đủ 10 lần, không trộn kiểu $r$, không trộn loại mô hình | **Đọc code** + test |

---

## 2. Việc phải sửa (theo mức độ)

### P0 — Chặn merge (bảng sẽ trống hoặc sai)

**P0-1. Bảng bỏ qua toàn bộ số liệu đã chạy (20/20 hàng `INCOMPLETE`).** *Đã chạy.*
- Tái hiện: sao chép `orange/results/*.csv` hiện tại vào một thư mục tạm, chạy
  `julia --project=orange orange/scripts/official_tables.jl <thư_mục_tạm> <thư_mục_report_tạm>`. Cả `table_official_P1` và `P2` đều ra `Model type = none`, `Run count = 0`, `Best MLU = N/A`, `Status = INCOMPLETE` cho mọi hàng.
- Nguyên nhân: `orange/scripts/official_common.jl` dòng 26–28 chỉ nhận dòng có `routing_mode=pathcount`, `objective_mode=pure_mlu`, `experiment=official`. Số liệu cũ (định dạng 19 cột, mục tiêu có phạt) không có các cột này.
- Cần: (a) nhận dữ liệu cũ nhưng **gắn nhãn** (ví dụ cột `data_origin=legacy`, hiển thị riêng, không lẫn vào mẫu "official"), **hoặc** (b) ghi rõ trong tài liệu rằng toàn bộ phải chạy lại và nêu ước lượng thời gian (setA-04, 05 ở $t=0,1$ mỗi lần 1–2 giờ, 10 lần mỗi hàng).
- Tiêu chí xong: chạy lệnh trên bản sao số liệu hiện tại → các hàng setA-01…05 ($t=0$) và setA-01…03 ($t=0,1$) hiện giá trị, không `INCOMPLETE`.

**P0-2. Nhãn trạng thái sai cho mô hình đầy đủ.** *Đọc code* (`official_common.jl` dòng 134).
- Hiện: mọi kết quả không `Optimal` đều bị gắn `Feasible upper bound (restricted)`, kể cả khi `model_type == full_arc`. Ví dụ setA-04 (mô hình theo cung, Not Optimal) sẽ bị gọi là "restricted" dù không hề thu hẹp.
- Cần: chỉ gắn "restricted" khi `model_type == restricted_waypoint`; với `full_arc` dùng `Optimal` / `Not Optimal` / `Infeasible` (đúng ba nhãn trong readme của thầy).
- Thêm test: một hàng `full_arc` có `status=Not Optimal` phải ra `Not Optimal`.

**P0-3. `run_official_wp.jl` không bật sinh cột và LNS.** *Đọc code* (dòng 22).
- `run_wp_instance` được gọi với mặc định `use_colgen=false`, `use_lns=false`. Trong số liệu hiện có, chính sinh cột và LNS đã đưa MLU của setA-10, 13, 16, 19 từ khoảng 1,0 xuống 0,04–0,5. Chạy theo script này các hàng lớn sẽ kém hơn nhiều.
- Cần: thêm tham số bật `use_colgen`, `use_lns` (và thời gian LNS), đặt mặc định như đã dùng (`cg`, `lns 300`–`900`), ghi vào cột CSV để biết cấu hình đã chạy.

**P0-4. Xung đột khi merge vào `main` hiện tại (`0bc0c9e`).** *Đã chạy* (`git merge-tree`).
- Hai file xung đột: `orange/scripts/official_tables.jl` và `orange/src/experiment.jl`.
- Cần: gộp lại với `main` mới nhất và **giữ cả** những thay đổi M1 đã làm ở hai file này:
  1. `experiment.jl`: ở chế độ không phải official, nghiệm của mọi lần chạy khác lần 1 được lưu `...-run<k>-srpaths.json`; `verify_srpaths.py` đối chiếu file đó với đúng dòng `run == k`.
  2. `official_tables.jl` (bản cũ của M1): nhãn hàng thu hẹp `(1-wp)` và cận dưới từ $t=0$ cho Bảng 2. Nếu giữ bản mới của Hùng, nên có hai tính chất này (hoặc tương đương).

### P1 — Nên sửa trước khi dùng cho báo cáo

**P1-1. Tối ưu từ điển không chạy nổi ngay cả với setA-01.** *Đã chạy.*
- Tái hiện: `julia --project=orange orange/scripts/run_lex_pathcount.jl project/setA/setA-01 1 120 out.json` → lỗi `lexicographic rank 1 was not optimal: TIME_LIMIT` (`model.jl:226`). Trong khi mô hình MLU thuần giải setA-01 trong 0,7 s.
- Nguyên nhân dự đoán: công thức sắp xếp bằng ma trận gán $L\times L$ biến nhị phân (80 cung → 6 400) với hằng big-M lớn, cận lỏng; lại phải giải $L$ hạng liên tiếp (80 lần). Các test chỉ dùng đồ thị toy.
- Cần: (a) ghi rõ giới hạn "chỉ chạy được với đồ thị cực nhỏ"; (b) thay bằng cách không dùng big-M, ví dụ công thức tích luỹ tuyến tính của Ogryczak–Tamir (tối thiểu tổng $k$ tải lớn nhất bằng biến liên tục, lần lượt cho $k=1,2,\dots$); (c) hoặc chỉ làm $K$ tầng đầu (ví dụ $K=5$) và nói rõ điều đó là tối ưu từ điển $K$ tầng.
- Tiêu chí xong: chạy được setA-01 và setA-02 ($t=0$) đến hết (hoặc đến $K$ tầng), vector tải đã sắp xếp khớp với `check_lexicographic_solution`.
- Lưu ý: **không đưa vào bảng chính** cho tới khi chạy được.

**P1-2. Cột trạng thái không theo ba nhãn của thầy.** *Đọc code.*
- Readme của thầy: `Optimal`, `Not Optimal`, `Infeasible`. Nhánh dùng thêm `Feasible upper bound (restricted)`, `INCOMPLETE`, `UNVERIFIED`.
- Cần: cột `Status` chỉ dùng ba nhãn của thầy; phần "hạn chế", "chưa đủ lần", "chưa kiểm chứng" để ở cột riêng.

**P1-3. Bảng mất cột so sánh "tốt nhất biết được".** *Đọc code* (`best_known.jl` bị thay toàn bộ).
- Bản cũ có `lb_orig`, `lb_1wp`, `gap_orig`, `gap_1wp` và cột "Best known (any method)" để so hàng của mô hình thầy với kết quả mô hình thu hẹp (ví dụ setA-05 $t=0,1$: 0,99999 so với 0,205). Bản mới không có.
- Cần: giữ lại (hoặc nêu lý do bỏ).

### P2 — Cải thiện thêm

- **P2-1.** Cột `solve_time`: nêu trong tài liệu là thời gian giải của HiGHS trong `optimize!` (không gồm dựng mô hình); nhiều lần chạy thực tế vượt giới hạn tới ~2 lần (HiGHS) — cần cách xử lý/ghi chú (hiện M1 dùng `hang_guard.py` dừng lần chạy quá 7800 s).
- **P2-2.** Thêm test cho: dữ liệu cũ, nhãn của mô hình đầy đủ Not Optimal, mô hình thu hẹp có sinh cột/LNS.
- **P2-3.** Cho `official_tables.jl` in tên file nguồn của từng hàng và số lần chạy, để người đọc truy vết.

---

## 3. Kiểm tra sau khi sửa (Hùng chạy và dán kết quả)

1. `git fetch origin && git merge origin/main` (hoặc rebase) → không còn xung đột.
2. `julia --project=orange orange/test/runtests.jl` → toàn bộ Pass.
3. Sao chép `orange/results/*.csv` của `main` vào thư mục tạm, chạy `official_tables.jl` trên đó → **không còn 20/20 `INCOMPLETE`** (P0-1), hàng setA-04 ($t=0$) hiện `Not Optimal` chứ không `restricted` (P0-2).
4. `run_official_wp.jl` có tham số sinh cột và LNS; chạy thử một instance cỡ vừa (ví dụ setA-09, $t=0$) và so MLU với `orange/results/best_known.csv`.
5. Nếu giữ mục tiêu từ điển: `run_lex_pathcount.jl` chạy hết với setA-01 (P1, ≤ 5 phút).

**Đừng làm:** ghi vào `orange/results/` trên máy M1 hoặc trên nhánh `main` khi M1 còn đang chạy (M1 dự kiến xong khoảng 02:00–07:00 sáng 21/10); chỉ làm trên nhánh `hung` và bản sao số liệu.

---

## 4. Ghi chú về thời gian

- M1 chạy xong setA-05 $t=0,1$ seed 6–10 vào khoảng 02:00–07:00 ngày 21/10; mốc gộp cuối của nhóm: ~12:00 ngày 21/10 (T4).
- Nếu P0-1 chọn phương án (b) (chạy lại hết ở chế độ official), cần tính: Bảng 2 setA-04 và setA-05 mỗi hàng 10 lần × 1–2 giờ ≈ 20–40 giờ máy — **không kịp** nếu chỉ một máy. Khuyến nghị phương án (a): nhận số liệu cũ có gắn nhãn.
