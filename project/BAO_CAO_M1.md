# Báo cáo công việc của M1 (tài liệu sống, cập nhật dần)

**Dự án:** Orange — ROADEF 2026 "Keep The Flow!", bài toán T-Adaptive Segment Routing (T-ASR), môn Mô hình hoá toán học (SOICT).
**Người viết:** M1 (người điều phối; chạy trên máy chính của nhóm).
**Mục đích file:** ghi lại **M1 đã làm gì, vì sao, kết quả ra sao, còn gì dở**, đủ chi tiết để nhóm và thầy truy vết. File này được **cập nhật dần** (xem mục 11, nhật ký cập nhật). Nội dung thực nghiệm đầy đủ nằm ở `project/BAO_CAO_KET_QUA_THUC_NGHIEM.md`; nhật ký giờ-từng-sự-kiện nằm ở `orange/results/RUN_JOURNAL.md`.

> **Cập nhật lần cuối:** Thứ Ba 20/10/2026, ~10:50.

---

## 0. Trạng thái hiện tại (đọc mục này trước)

| Hạng mục | Trạng thái |
|---|---|
| Mô hình JuMP theo đề (Step 1–9 của thầy) | ✅ xong, test tự động đều đạt |
| Bảng 1 ($t=0$, 1800 s), 20 hàng | ✅ đủ 20 hàng; setA-01…05 đủ 10 lần; setA-06…20 mới 1 lần (mô hình waypoint, dấu `*`) |
| Bảng 2 ($t=0,1$, 3600 s), 20 hàng | ✅ đủ 20 hàng; setA-01, 02, 03 đủ 10 lần; **setA-04 mới 5/10, setA-05 mới 5/10**; setA-06…20 mới 1 lần |
| Kiểm chứng độc lập các lời giải | ✅ 93 file, 0 lỗi |
| Truy vết (manifest, log, zip, nhật ký) | ✅ đang chạy tự động |
| Hướng dẫn và prompt cho M2, M3 | ✅ xong, đã kiểm tra từ bản clone sạch; **M2 và M3 chưa bắt đầu** |
| M1 chạy nốt setA-04, setA-05 ($t=0,1$) | 🔄 đang chạy: setA-04 lần 6 (bắt đầu 09:43); dự kiến xong ~20:00 |
| `main` là bản chính | ✅ đồng bộ với `feature/tasr` (squash merge, không có đồng tác giả Claude) |
| Báo cáo LaTeX ≤ 10 trang | ⬜ do người khác viết (M1 cung cấp số liệu) |

---

## 1. Vai trò và phạm vi của M1

- **M1:** phân tích đề, thiết kế và cài đặt mã nguồn, chạy thực nghiệm chính, kiểm chứng, truy vết, và **điều phối** M2, M3.
- **M2, M3:** chạy các thử nghiệm cải tiến tối ưu (mô hình waypoint + LNS) trên máy riêng, theo `HUONG_DAN_M2_M3_FINAL.md`.
- **Báo cáo LaTeX:** do người khác viết; M1 làm tài liệu nền và số liệu.
- **Ưu tiên theo chỉ đạo:** *yêu cầu tối thiểu của thầy trước*, tối ưu và cải thiện sau; mọi kết quả phải lưu để thầy truy vết; commit và push dưới tên của người dùng, không có đồng tác giả Claude.

---

## 2. Những việc M1 đã làm

### 2.1. Phân tích đề và lập kế hoạch

1. Đọc `project/readme`, đề PDF, `calculating_r.pdf`; viết **`project/BAI_TOAN_FINAL.md`**: phân tích đầy đủ bài toán, mô hình toán (LaTeX), dữ liệu SetA, các điểm dễ sai.
2. Phát hiện: công thức $r$ trong `calculating_r.pdf` (đếm đường ngắn nhất) **khác** định nghĩa ECMP từng chặng của đề (ví dụ 2/3 so với 0,5). Đã kiểm chứng bằng code trên ví dụ mẫu. Quyết định: bảng chính thức dùng công thức của thầy, vẫn chạy ECMP để đối chiếu.
3. Phát hiện: script Pluto của thầy **báo lỗi trên 10/20 instance** (`multigraph: true`); đã kiểm tra không instance nào có cung song song; code đọc JSON trực tiếp.
4. Lập kế hoạch thực hiện (`project/KE_HOACH_THUC_HIEN.md`) và kế hoạch các giai đoạn (`project/KE_HOACH_CAC_GIAI_DOAN.md`); phân tích phân công nhóm.

### 2.2. Mã nguồn (`orange/`)

| Thành phần | File | Việc |
|---|---|---|
| Đọc dữ liệu | `src/io.jl` | JSON → đồ thị, $c(a)$, $\delta(d,t)$, MaxSeg, ngân sách |
| Hệ số $r$ | `src/ecmp.jl` | hai chế độ `:ecmp` và `:pathcount` |
| Kiểm chứng nghiệm | `src/verify.jl` | tính lại tải, số đoạn, ngân sách, MLU |
| Mô hình theo cung (của thầy) | `src/model.jl` | MILP đầy đủ, chặn kích thước, ước lượng bộ nhớ |
| Mô hình waypoint | `src/wpmodel.jl` | MILP theo đường chọn waypoint, sinh cột (dual + reduced cost) |
| LNS | `src/lns.jl` | đóng băng demand, giải lại lân cận |
| Heuristic | `src/heuristic.jl` | tìm kiếm cục bộ (chưa dùng cho bảng chính thức) |
| Runner thực nghiệm | `src/experiment.jl` | chạy, ghi CSV, seed, log solver, presolve tắt khi > 1,2 triệu biến |
| Test | `test/runtests.jl` | đọc cả 20 instance, khớp ví dụ mẫu của đề, đối chiếu vét cạn |

Một reviewer độc lập đã xem toàn nhánh; M1 sửa các lỗi mức Important (chu trình trong nghiệm khi có ngân sách, ngưỡng gap/ε) và thêm khởi tạo MILP bằng heuristic.

### 2.3. Kịch bản và công cụ (`orange/scripts/`)

- **Chạy:** `run_experiments.jl` (mô hình theo cung), `run_wp.jl` (waypoint/CG/LNS), `run_heuristic.jl`.
- **Làm bảng:** `official_tables.jl` (gộp CSV, kể cả hậu tố `-rA-B`; xuất `.md/.csv/.tex`), `best_known.jl`, `r_difference.jl`, `compare_r_modes.jl`, `budget_sensitivity.jl`.
- **Kiểm chứng và truy vết:** `verify_srpaths.py` (độc lập, viết bằng Python), `make_manifest.py` (SHA-256), `package_results.py` (zip sao lưu), `status.py`.
- **Vận hành:** `watchdog.ps1` (canh RAM), `keep_awake.ps1` (không cho máy ngủ), `preflight.py`, `overnight_m1.py` (bộ lập lịch qua đêm), `fill_missing_m1.sh` (chạy nốt các lần còn thiếu).
- **Chia việc cho nhóm:** `check_range.py`, `pack_member_results.py`, `publish_member_results.py`, `merge_member_branch.py`.

### 2.4. Thực nghiệm

- **Phase 1 (yêu cầu tối thiểu của thầy)** xong lúc 00:22 ngày 20/10: hai bảng chính thức đủ 20 hàng, 92 lời giải kiểm chứng (sau này 93), manifest, zip sao lưu.
- **Các lần chạy bổ sung** (seed 4–10) cho hàng chậm: setA-04 $t=0$ (đủ 10), setA-02 $t=0,1$ (đủ 10), setA-03 $t=0,1$ (đủ 10), setA-05 $t=0,1$ (5 lần; pilot), setA-04 $t=0,1$ (5 lần, đang chạy tiếp).
- **Cải tiến thuật toán:** LNS cho setA-10, 13, 16, 19 (hạ MLU rất mạnh, ví dụ setA-13 $t=0,1$: 0,9017 → 0,0769); "pipeline nhanh" cho setA-16, 19 ở $t=0,1$ (MILP kẹt ở gốc).
- **Quyết định về cách chạy:** chạy tuần tự, canh RAM, tránh sập máy; không chạy hai tiến trình setA-04 $t=0,1$ cùng lúc.

### 2.5. Kiểm chứng và truy vết

- Kiểm tra độc lập (Python) tất cả `*-srpaths.json`: **93 file, 0 vi phạm**, MLU khớp CSV chênh 0.
- Manifest SHA-256 cho 350+ file kết quả và 60 file đầu vào; zip sao lưu mỗi 30 phút ra `C:\Users\X1\Project\SOICT_results_backup`.
- Mỗi lần chạy có seed riêng (= chỉ số lần chạy) và log solver riêng (`orange/results/solverlogs/`).
- Nhật ký `RUN_JOURNAL.md` ghi giờ-từng-sự-kiện, sự cố, quyết định.

### 2.6. Điều phối nhóm (M2, M3)

1. Chia phân công ban đầu (setA-04 và setA-05 ở $t=0,1$ cho M2, M3). Vì M2, M3 **chưa chạy**, M1 gánh cả đêm bằng bộ lập lịch qua đêm.
2. Từ sáng 20/10, đổi vai M2, M3 sang **thử nghiệm cải tiến tối ưu** (LNS trên các hàng chưa tinh chỉnh): M2 setA-06, 09, 11, 12 ($t=0,1$) và 10, 13 ($t=0$); M3 setA-18, 14, 15 ($t=0,1$) và 14 ($t=0$), kèm việc thêm tuỳ chọn setA-19 ($t=0$).
3. Viết **`HUONG_DAN_M2_M3_FINAL.md`** (bản chuẩn), **`PROMPT_M2_M3.md`** (prompt sẵn cho coding agent), `project/DE_XUAT_CAI_TIEN_TOI_UU.md` (lý do chọn instance), `project/PHAN_TICH_YEU_CAU_VA_PHAN_VIEC.md`, `project/KIEM_TRA_CHONG_CHEO_M1_M2_M3.md`.
4. **Kiểm tra chồng chéo và xung đột** giữa M1/M2/M3: không trùng việc, không trùng tên file, mỗi bên một nhánh git riêng; đã chạy thử từ đầu đến cuối trên bản clone sạch từ GitHub.
5. Sửa các lỗi phát hiện khi kiểm tra: script đẩy kết quả bỏ qua file mới; cách ghi log trên Windows; bỏ `git pull` khỏi quy tắc; script gộp của M1 lấy điểm xuất phát đúng; hướng dẫn đổi sang clone `main`.

### 2.7. Quản lý git

- `feature/tasr` là nhánh làm việc của M1; `main` là bản chính, được **squash merge** từ `feature/tasr` mỗi lần chốt, nên `main` **không có dòng Co-Authored-By của Claude**.
- Nhánh `feature/tasr` còn 17 commit cũ có dòng đồng tác giả; đã quyết không viết lại lịch sử, vì `main` đã sạch.
- M2 và M3 đẩy lên `results/m2`, `results/m3`; M1 gộp bằng `merge_member_branch.py`.

---

## 3. Dòng thời gian rút gọn

| Thời điểm | Sự kiện chính |
|---|---|
| 19/10 ~09:30–12:00 | Đọc đề, phân tích, cài đặt Task 0–6, test khớp vét cạn |
| 19/10 11:12–14:02 | Thực nghiệm đầu tiên (mô hình theo cung, waypoint, sinh cột), watchdog, review độc lập |
| 19/10 14:02 | Bắt đầu bảng chính thức với $r$ theo công thức của thầy |
| 19/10 18:40–19:10 | Máy ngủ (Modern Standby) → thêm `keep_awake.ps1` |
| 19/10 20:12–20:39 | Chẩn đoán HiGHS: presolve bỏ qua giới hạn thời gian → tắt presolve khi > 1,2 triệu biến |
| 19/10 21:52, 23:10 | Watchdog dừng hai tiến trình setA-04 $t=0,1$ vì hết RAM → sửa watchdog, rút quy tắc |
| 19/10 23:12 | Kiểm tra độc lập 91 file: 0 vi phạm |
| 20/10 00:15–00:22 | **Phase 1 xong:** hai bảng đủ 20 hàng, 92 file kiểm chứng, manifest, zip |
| 20/10 00:30 | M2/M3 chưa chạy → bộ lập lịch qua đêm cho M1 |
| 20/10 01:06–08:20 | setA-05 $t=0,1$ seed 1–5 (pilot) |
| 20/10 08:20–10:50 | Báo cáo kết quả, đề xuất tối ưu, hướng dẫn và prompt cho M2/M3, kiểm tra chồng chéo, `main` đồng bộ |
| 20/10 08:41 → | M1 chạy nốt setA-04 lần 5–10, setA-05 seed 6–10 |

---

## 4. Kết quả đạt được (tóm tắt; chi tiết ở `BAO_CAO_KET_QUA_THUC_NGHIEM.md`)

- **Hàng chạy bằng mô hình của thầy (`arc-pc`):**
  - Bảng 1: setA-01, 02, 03, 05 **tối ưu 10/10 lần** (0,8 s–5 phút); setA-04 **Not Optimal** (MLU 0,50105, gap 0,19), trong khi mô hình waypoint tìm được **0,45912**.
  - Bảng 2: setA-01, 02, 03 giải được (một số lần ở ngưỡng thời gian bị nhãn Not Optimal do máy bận); setA-04 (MLU 0,58857) và setA-05 (MLU 0,99999) **kẹt ở nút gốc**; mô hình waypoint cho 0,58281 và **0,20499**.
- **Hàng chạy bằng mô hình waypoint (`*`, setA-06…20):** nhiều hàng tối ưu cho bài toán thu hẹp; LNS giảm MLU 86–96 % ở các instance nhiều demand (06, 10, 13, 16, 19).
- **Phát hiện hữu ích:** MLU của $t=0,1$ không thể thấp hơn tối ưu của $t=0$; nên setA-07, 08, 17, 20 ở Bảng 2 thực chất đã tối ưu cho bài toán thu hẹp (Bảng 2 đang ghi nhãn thận trọng "Not Optimal\*").
- **Độ tin cậy:** 93/93 nghiệm kiểm chứng độc lập đạt; hệ số $r$ và MLU khớp ví dụ mẫu của đề; mô hình waypoint khớp vét cạn ($\text{maxSeg}=2$).

---

## 5. Sự cố đã gặp và bài học

| Sự cố | Ảnh hưởng | Xử lý / bài học |
|---|---|---|
| Máy ngủ 18:40–19:10 (19/10) | một số lần chạy bị kéo dài | `keep_awake.ps1`; luôn bật giữ máy thức |
| Watchdog dừng hai tiến trình setA-04 $t=0,1$ (21:52, 23:10) | mất 1 lần chạy | sửa watchdog (dừng tiến trình ít CPU nhất); **không chạy hai tiến trình setA-04 $t=0,1$ cùng lúc** |
| HiGHS bỏ qua giới hạn thời gian ở presolve | lần chạy vượt xa 3600 s | tắt presolve khi > 1,2 triệu biến |
| Chạy song song làm méo thời gian | Optimal ↔ Not Optimal ở setA-02, 03 | ghi "Optimal k/n"; chạy lại hàng nhanh khi máy rảnh nếu cần |
| setA-05 $t=0,1$ seed 5 mất 7175 s | trung bình thời gian lệch (4327 s) | ghi chú trong báo cáo; chưa xác định nguyên nhân |
| Lỗi định dạng khi sửa tài liệu bằng script (ký tự điều khiển trong đường dẫn) | đường dẫn Windows sai trong hướng dẫn | phát hiện bằng kiểm tra tự động, đã sửa; từ đó kiểm tra ký tự lạ sau mỗi lần sửa |
| Script đẩy kết quả bỏ qua file mới của M2, M3 | sẽ mất kết quả của họ | phát hiện khi kiểm tra chồng chéo, đã sửa và thử lại |

---

## 6. Quyết định M1 đã tự chốt (thầy không trả lời)

1. Bảng chính thức dùng $r$ theo `calculating_r.pdf`; ECMP vẫn chạy để đối chiếu.
2. Step 9 của thầy ghi "only time period 0" (lỗi đánh máy); hiểu là $t=0,1$ có ngân sách.
3. Mục tiêu cài đặt: $\min z+\varepsilon\sum x$ (xấp xỉ mục tiêu từ điển).
4. Quy tắc số lần chạy: 10 nếu lần đầu ≤ 120 s, ngược lại 3 lần rồi bổ sung dần.
5. Mô hình theo cung bị bỏ qua khi quá lớn hoặc thiếu RAM; dùng mô hình waypoint (một waypoint mỗi demand), đánh dấu `*`.
6. `main` là bản chính, cập nhật bằng squash merge (không có đồng tác giả Claude).
7. Chia việc: M1 chạy hai instance lớn nhất ở $t=0,1$; M2, M3 chạy thử nghiệm cải tiến trên instance riêng.

---

## 7. Đang chạy và dự kiến

| Việc | Tiến độ | Dự kiến xong |
|---|---|---|
| setA-04 $t=0,1$ lần 6–10 | lần 6 đang chạy (từ 09:43) | ~14:50 |
| setA-05 $t=0,1$ seed 6–10 | chưa bắt đầu (chạy sau setA-04) | ~20:00 (nếu không có lần nào chậm bất thường như 7175 s) |
| M2: 6 lệnh LNS | chưa bắt đầu | tuỳ M2 |
| M3: 4 lệnh LNS (+ tuỳ chọn setA-19) | chưa bắt đầu | tuỳ M3 |

Các tiến trình hỗ trợ đang chạy: làm mới `STATUS.md` mỗi phút, zip sao lưu mỗi 30 phút, giữ máy thức, canh RAM.

---

## 8. Việc còn lại của M1

**Chắc chắn phải làm:**
1. Khi setA-04, setA-05 ($t=0,1$) xong: tạo lại `best_known.csv` và hai bảng, kiểm chứng độc lập, manifest, zip, cập nhật nhật ký và báo cáo kết quả; squash merge vào `main`.
2. Khi M2, M3 đẩy kết quả: `merge_member_branch.py m2`/`m3` → `best_known.jl` → `official_tables.jl` → `verify_srpaths.py` → `make_manifest.py`.
3. Dừng các tiến trình nền (watchdog, keep_awake, sao lưu, `status.py --loop`) khi mọi thực nghiệm xong.

**Nên làm nếu còn thời gian (theo thứ tự ưu tiên, đã đề xuất ở `DE_XUAT_CAI_TIEN_TOI_UU.md`):**
- O1: sửa nhãn hàng `*` bằng cận dưới từ $t=0$ ("Optimal (restricted)" cho setA-07, 08, 17, 20).
- WP2: chạy lặp 10 lần các hàng setA-06…20 (cần thêm tham số số lần cho `run_wp.jl`).
- O4: cận dưới từ bài toán chỉ $t=1$; O5: khởi tạo mô hình theo cung của setA-04 $t=0$ bằng nghiệm waypoint (hàng `arc-pc` của thầy sẽ không kém 0,45912).

**Không thuộc M1:** viết báo cáo LaTeX ≤ 10 trang.

---

## 9. Bản đồ file (để truy vết)

| Cần xem | File |
|---|---|
| Phân tích đề đầy đủ | `project/BAI_TOAN_FINAL.md` |
| Báo cáo kết quả chi tiết | `project/BAO_CAO_KET_QUA_THUC_NGHIEM.md` |
| Phân tích yêu cầu của thầy và phân việc | `project/PHAN_TICH_YEU_CAU_VA_PHAN_VIEC.md` |
| Đề xuất cải tiến tối ưu | `project/DE_XUAT_CAI_TIEN_TOI_UU.md` |
| Kiểm tra chồng chéo M1/M2/M3 | `project/KIEM_TRA_CHONG_CHEO_M1_M2_M3.md` |
| Hướng dẫn chuẩn và prompt cho M2, M3 | `HUONG_DAN_M2_M3_FINAL.md`, `PROMPT_M2_M3.md` |
| Bảng chính thức | `orange/results/table_official_P1.md/.csv`, `table_official_P2.md/.csv`; `report/table_official_P*.tex` |
| MLU tốt nhất theo mọi phương pháp | `orange/results/best_known.csv` |
| Từng lần chạy | `orange/results/setA-*-P{1,2}-pc*.csv` |
| Lời giải kiểm chứng | `orange/results/*-srpaths.json`, `verification.csv` |
| Log solver | `orange/results/solverlogs/` |
| Nhật ký giờ-từng-sự-kiện | `orange/results/RUN_JOURNAL.md`, `overnight_m1.log`, `fill_missing_m1.log` |
| Toàn vẹn dữ liệu | `orange/results/MANIFEST.csv/.md`, `MANIFEST_INPUTS.csv` |
| Mã nguồn và cách dùng | `orange/`, `orange/README.md` |

---

## 10. Phần sẽ điền khi M1 chốt (chưa có số liệu)

- [ ] Số lần chạy cuối cùng của từng hàng ở cả hai bảng.
- [ ] Bảng chính thức sau khi gộp kết quả M2, M3.
- [ ] Danh sách hàng `*` có MLU cải thiện nhờ M2, M3 (trước → sau).
- [ ] Thời điểm chốt `main` và commit cuối.
- [ ] Danh sách việc **không** làm được và lý do.

---

## 11. Nhật ký cập nhật file này

| Thời điểm | Cập nhật |
|---|---|
| 20/10 ~10:50 | Tạo file; ghi toàn bộ việc đã làm đến lúc này, trạng thái, sự cố, quyết định, việc còn lại |
