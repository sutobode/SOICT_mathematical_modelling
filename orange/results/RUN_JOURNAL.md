# Nhật ký chạy thực nghiệm (Run journal)

Ghi lại theo thứ tự thời gian **mọi lần khởi động, dừng, sự cố và quyết định** của thực nghiệm, để truy vết đầy đủ. Giờ theo đồng hồ máy (Windows, UTC+7), ngày 19/10/2026 nếu không ghi khác. Log gốc nằm trong `log-*.txt` (cùng thư mục) và `solverlogs/` (log nguyên văn của HiGHS cho các lần chạy từ 22:00 trở đi). Kết quả: các file `setA-XX-*.csv`. Truy vết file: `MANIFEST.md`, `MANIFEST.csv`.

## A. Cấu hình cố định

- Máy: Intel Core i7-1270P, 31,6 GB RAM, Windows 11 (`environment.txt`). Julia 1.13.1, JuMP, HiGHS (khóa phiên bản: `orange/Manifest.toml`).
- HiGHS: 1 luồng, `mip_rel_gap = 1e-6`, `random_seed` = số thứ tự lần chạy; presolve tắt khi mô hình theo cung có trên 1,2 triệu biến (xem C.5).
- Giới hạn thời gian theo thầy: 1800 s cho chỉ $t=0$ (Bảng 1), 3600 s cho $t=0,1$ có ngân sách (Bảng 2).
- Hàm mục tiêu: min z + ε·Σx, ε = 1e-7/|D| (z là MLU). Gap = 1 − bound/obj.
- Số lần chạy: 10 nếu lần đầu giải trong 120 s, nếu không 3 lần; các lần 4–10 của dòng chậm được chạy bổ sung (file hậu tố `-r4-10`, `-r2-10`, `-r7-10`).

## B. Dòng thời gian

| Giờ | Sự kiện |
|---|---|
| ~09:30–11:00 | Đọc yêu cầu (`project/readme`, đề PDF, `calculating_r.pdf`); viết `BAI_TOAN_FINAL.md`; phát hiện công thức $r$ trong `calculating_r.pdf` (đếm đường) khác định nghĩa ECMP của đề; kiểm chứng trên ví dụ toy (r(v0,v5,a1,4,0) = 0,5 ECMP, 2/3 đếm đường). |
| ~11:00–12:00 | Cài đặt Task 0–6 (package `orange/`, đọc dữ liệu, $r$, mô hình JuMP, kiểm tra nghiệm, runner). Test khớp vét cạn trên toy. |
| 11:12 | Chạy thực nghiệm mô hình theo cung, $r$ = ECMP, $t=0$, 1800 s (log `log-P1.txt`). Kết quả instance 01–05; 06–20 `SKIPPED_TOO_LARGE`. |
| 11:23 | Chạy mô hình waypoint đầy đủ (K = n−2) cho instance 01–13, $t=0$ (`log-wp-P1.txt`). Dừng lúc ~13:45 ở setA-13 (trùng với sinh cột). |
| 11:43 | Chạy mô hình waypoint đầy đủ, $t=0,1$ (`log-wp-P2.txt`). Dừng lúc ~13:45 ở setA-06 (trùng với sinh cột). |
| 12:07 | Bật watchdog RAM (`watchdog.log`). |
| 12:15 | Sinh cột (ECMP) cho cả 20 instance, $t=0$ (`log-wp-cg-P1.txt`). Bản có làm giàu cột thay cho bản đầu (đã dừng). |
| ~12:00 | Review toàn nhánh bởi một reviewer độc lập; sửa 2 lỗi Important (chu trình trong nghiệm, gap/ε), thêm khởi tạo MILP bằng heuristic. |
| 13:04 | Chạy mô hình theo cung ECMP, $t=0,1$ (`log-P2.txt`); dừng 14:02 để nhường bảng chính thức. |
| 14:02 | **Bảng chính thức** với $r$ theo công thức của thầy (`-pc`): `log-pc-P1.txt`, `log-pc-P2.txt`. Đo `r_difference`: hai công thức trùng ở 18/20 instance (setA-18 và setA-20 lệch 1 cặp nút). |
| 14:17 | Tách chuỗi chính thức $t=0$ (instance 4–20) và $t=0,1$ (instance 1–20) thành hai tiến trình (`log-pc-P1b.txt`, `log-pc-P2.txt`). |
| ~14:30–16:00 | LNS thử cho setA-10, 13, 14 ($t=0$): setA-13 giảm 0,04487 → 0,03889. |
| 17:01 | setA-10 ($t=0,1$) sinh cột + MILP: kẹt ở gốc (0 nút), MLU 1,0; LNS (15 phút) cho 0,1087. |
| **18:40–19:10** | **Máy ngủ (Windows Modern Standby)**, hai khoảng 18:40–18:54 và 18:54–19:10 (nhật ký `Kernel-Power`). Mọi tiến trình đóng băng; một số lần chạy dài có thời gian thực bị kéo dài. Bật `keep_awake.ps1` lúc 19:13. |
| 19:11 | LNS cho setA-13 ($t=0,1$): 0,9017 → 0,0769. |
| 20:12–20:39 | Chẩn đoán HiGHS: mô hình theo cung setA-04 $t=0,1$ (1,47 triệu biến) với giới hạn 120 s: presolve bật chạy hơn 20 phút; presolve tắt trả về ở 242 s. |
| **20:39** | **Sửa**: tắt presolve khi mô hình có trên 1,2 triệu biến; thêm bảo vệ bộ nhớ cho mô hình theo cung. Khởi động lại chuỗi chính thức $t=0,1$ từ setA-04 (commit `77b6346`). |
| 21:28 | setA-16 ($t=0,1$) sinh cột xong: Not Optimal, MLU 0,9426 (MILP kẹt ở gốc); chuỗi sinh cột dừng; setA-17, 18, 20 chạy song song (`log-wp-cg-P2-17-18-20.txt`), setA-19 (`log-wp-cg-P2-19.txt`, dừng 21:53 vì quá nặng). |
| 21:33 | Đường nhanh (bỏ MILP, sinh cột thời kỳ đầu, LNS) cho setA-16 rồi 19 ($t=0,1$): `log-wp-fast-P2.txt`. |
| 21:44–21:45 | Chạy bổ sung (seed 4–10): setA-04 $t=0$ (`log-pc-P1-04-r4-10.txt`), setA-02 $t=0,1$ (`log-pc-P2-02-r4-10.txt`), setA-05 $t=0$ rồi setA-03 $t=0,1$ (`log-pc-P1-05-r4-10.txt`, `log-pc-P2-03-r4-10.txt`). |
| **21:52:32** | **Watchdog dừng tiến trình chính thức setA-04 $t=0,1$** (6,39 GB) vì RAM trống 1,07 GB (do các tiến trình bổ sung vừa khởi động). Lần chạy 1 đã lưu (MLU 0,58857, Not Optimal, 3614,6 s); **lần chạy 2 bị mất**. |
| 21:53 | Sửa watchdog: dừng tiến trình **ít CPU nhất** trong các tiến trình lớn (bảo vệ lần chạy dài). |
| 21:55 | Khởi động lại setA-04 $t=0,1$: lần 2–10, tuần tự (`log-pc-P2-04-r2-10.txt`), tự chờ RAM trống ≥ 10 GB. |
| 22:55 | Khởi động tiến trình thứ hai setA-04 $t=0,1$ lần 7–10 (`log-pc-P2-04-r7-10.txt`). |
| **23:10:53** | **Watchdog dừng tiến trình thứ hai** (5,8 GB) vì RAM trống 1,03 GB; tiến trình chính được bảo vệ. Kết luận: **không chạy hai tiến trình setA-04 $t=0,1$ cùng lúc** trên máy này (đỉnh RAM khi dựng mô hình ~8 GB). |
| 23:12 | Kiểm tra độc lập (Python) cho 91 file nghiệm: 0 vi phạm, MLU khớp tuyệt đối (`verification.csv`, `log-verify-all.txt`). |
| 23:50 | Gói sao lưu zip (mỗi 30 phút, `C:\Users\X1\Project\SOICT_results_backup`). |
| 23:57–00:20 (20/10) | Chuẩn bị chia việc cho 2 thành viên khác: `HUONG_DAN_CHAY_SONG_SONG.md`, `START_HERE.md`, `AGENTS.md`, `project/AGENT_BRIEFS/`, các script `preflight.py`, `check_range.py`, `publish_member_results.py`, `merge_member_branch.py`, `pack_member_results.py` (đã thử trên kho cục bộ và trên bản clone mới từ GitHub). Phân công: M1 (máy này) giữ setA-04 $t=0$ lần 8–10, setA-02 và setA-03 $t=0,1$ lần 6–10, setA-04 $t=0,1$ lần 3–4; M2: pilot setA-05 lần 1, setA-04 $t=0,1$ lần 5–7, setA-05 lần 2–5; M3: setA-04 $t=0,1$ lần 8–10, setA-05 lần 6–10. Khoảng seed rời nhau. |
| 00:07 | setA-04 $t=0,1$ (bảng chính thức): lần 2 và 3 xong (Not Optimal, MLU 0,58857, 3603 s và 3611 s). |
| 00:15 | **Dòng cuối của Phase 1 xong:** setA-19 $t=0,1$ (đường nhanh: sinh cột thời kỳ đầu + LNS): MLU 0,10258. Hai bảng chính thức đủ 20 dòng. |
| 00:18–00:22 | Chốt Phase 1: tạo lại `best_known.csv` và hai bảng chính thức, kiểm tra độc lập 92 file nghiệm (0 vi phạm, MLU khớp tuyệt đối), manifest (350 file kết quả, 60 file đầu vào), zip sao lưu. Đẩy nhánh `feature/tasr` lên GitHub (commit `e9cacd5`). |
| 00:30–00:45 (20/10) | M2 và M3 **chưa bắt đầu**. Máy M1 gánh cả đêm: bộ lập lịch `orange/scripts/overnight_m1.py` (nhật ký `overnight_m1.log`) chờ setA-04 $t=0,1$ xong lần 1..4 (~01:05), dừng tiến trình đó, rồi chạy setA-05 $t=0,1$ mô hình theo đề seed 1–5 (làm pilot, ngân sách bộ nhớ 12 GB). Lý do: setA-04 $t=0,1$ cho kết quả gần như giống hệt giữa các lần (Not Optimal, MLU 0,5886), còn setA-05 chưa có lần nào theo đề. Phân công mới cho M2/M3: setA-05 seed 6–8 (M2), 9–10 (M3) sau khi kiểm tra pilot của M1; setA-04 $t=0,1$: M2 seed 5–7, M3 seed 8–10. Báo cáo tiến độ cho người dùng mỗi 45 phút. |

## C. Quyết định đã tự chốt (thầy không trả lời câu hỏi)

1. $r$: bảng chính thức dùng công thức của `calculating_r.pdf` (`-pc`); ECMP vẫn được chạy để kiểm chứng. Hai cách trùng ở 18/20 instance.
2. Bước 9 hiểu là giải chung $t=0$ và $t=1$ (readme bước 8: thêm $t=1$ và ngân sách).
3. Mục tiêu: min MLU.
4. Số lần chạy: 10 nếu lần đầu giải trong 120 s, nếu không 3; các lần 4–10 của dòng chậm chạy bổ sung vì còn thời gian đến mốc T4.
5. Presolve tắt cho mô hình theo cung trên 1,2 triệu biến (HiGHS không tôn trọng giới hạn thời gian ở presolve).
6. Mô hình theo cung bỏ qua khi |D|·P·n(n−1) > 3·10⁶ biến hoặc ước lượng RAM vượt 70% RAM trống; khi đó dùng mô hình waypoint (một waypoint mỗi demand), dấu `*` trong bảng.
7. Quy tắc cắt Phase 1b: 22:00 Thứ Ba 20/10, dòng nào chưa đủ 10 lần thì chốt số lần đã xong.

## D. Phát hiện chính

- **Một waypoint đủ trên các instance đã kiểm tra:** setA-05 (mô hình theo cung tối ưu thật = nghiệm waypoint đến 8 chữ số), setA-04 (cách cận dưới của bài toán gốc 0,011%), và mô hình hai waypoint không cải thiện ở setA-01, 03, 04, 05, 09.
- **Mô hình waypoint** (path-based) nhỏ hơn mô hình theo cung hàng trăm lần và giải tối ưu cho instance 01–09 trong vài giây; sinh cột + làm giàu cột mở rộng cho cả 20 instance; LNS gỡ các trường hợp MILP bị kẹt ở gốc B&B khi có ngân sách (setA-10: 1,0 → 0,1087; setA-13: 0,9017 → 0,0769; setA-16: 0,9426 → 0,5164).
- **Mô hình theo cung ở $t=0,1$ với setA-04 không chứng minh được tối ưu** (bound = 0, gap = 1,0 sau 3600 s; nghiệm 0,58857, trong khi nghiệm waypoint là 0,58281).
- **Thời gian đo bị nhiễu khi chạy song song** (setA-05 $t=0$: 172 s khi ít tải, ~330 s khi tải nặng; setA-02 $t=0,1$ chuyển từ Optimal ở ~2000 s sang Not Optimal ở 3600 s khi tải nặng). MLU không bị ảnh hưởng.

## E. Chỉ mục log

| Log | Nội dung |
|---|---|
| `log-P1.txt`, `log-P2.txt` | mô hình theo cung, $r$ = ECMP |
| `log-pc-P1*.txt`, `log-pc-P2*.txt` | **bảng chính thức** (mô hình theo cung, $r$ của thầy), cả các lần bổ sung `-r4-10`, `-r2-10`, `-r7-10` |
| `log-wp-*.txt` | mô hình waypoint: đầy đủ, sinh cột (`-cg`), LNS (`-lns`), đường nhanh (`-fast`) |
| `log-verify-all.txt` | kiểm tra độc lập bằng Python |
| `watchdog.log`, `keep_awake.log` | giám sát RAM, giữ máy thức |
| `solverlogs/*.log` | log nguyên văn HiGHS cho từng lần chạy theo cung (từ lần khởi chạy sau 22:00; các lần chạy trước đó chỉ có CSV) |
| `STATUS.md` | trạng thái tức thời |

## F. Việc đang chờ / vấn đề còn mở

- Dòng Bảng 2 của setA-19 (đường nhanh, `log-wp-fast-P2.txt`) chưa xong lúc 23:50.
- Phase 1b: bổ sung lần chạy để đủ 10 lần cho setA-04 ở cả hai bảng, setA-02 và setA-03 ở $t=0,1$; thử setA-05 ở $t=0,1$ nếu đủ RAM.
- Phase 1c: chạy lại các dòng nhanh một mình để có thời gian đo sạch.
- Các lần chạy 1–3 của mỗi dòng và solver log đầy đủ chỉ có từ 22:00 trở đi; ghi chú trong manifest.

- **20/10 08:41** — M2/M3 chưa đẩy kết quả (không có `origin/results/m2`, `origin/results/m3`). M1 tự chạy nốt phần còn thiếu của Bảng 2 bằng `orange/scripts/fill_missing_m1.sh` (tuần tự, mỗi lần một tiến trình, file riêng `-rK-K`): setA-04 $t=0,1$ lần 5–10, rồi setA-05 $t=0,1$ seed 6–10. Nhật ký: `orange/results/fill_missing_m1.log`. Nếu M2/M3 sau đó đẩy cùng các lần này thì bộ gộp bảng giữ bản đầu và cảnh báo trùng. `main` đã nhận bản squash `e245ed3` (chưa gồm các lần chạy này).

- **20/10 11:30** — setA-04 $t=0,1$ seed 6 (bắt đầu 09:43) vẫn chạy sau hơn 107 phút (CPU 6388 s) dù giới hạn 3600 s; log solver `setA-04-P2-pc-r6-6-run6.log` không in thêm dòng nào kể từ 09:48 (dòng cuối ở 274 s). Trước đó, setA-05 $t=0,1$ seed 5 cũng quá giới hạn (7175 s, `check=ok`, không qua nhánh giải lại "acyclic"), nên HiGHS đôi khi vượt giới hạn thời gian khoảng gấp đôi. Bổ sung `orange/scripts/hang_guard.py` (chạy từ 11:31, ngưỡng 7800 s, loại trừ PID 7720 của IDE; nhật ký `hang_guard.log`): tiến trình julia chạy quá ngưỡng bị dừng; seed đó không có dòng CSV, chuỗi `fill_missing_m1.sh` chuyển sang seed kế tiếp, seed bị bỏ chạy bù sau. Ghi chú cho báo cáo: thời gian CPU trung bình của setA-05 $t=0,1$ bị lệch bởi lần 7175 s; dùng trung vị hoặc nêu từng lần.

- **20/10 ~16:00** — Đối chiếu bản audit (xem `project/DOI_CHIEU_AUDIT.md`). Thay đổi: (1) `official_tables.jl`: nhãn hàng `*` thành `(1-wp)`; Bảng 2 dùng cận dưới `lb_1wp` của $t=0$ làm cận dưới của $t=0,1$ (hợp lệ vì MLU hai thời kỳ ≥ MLU tối ưu $t=0$) → setA-07, 08, 17, 20 là `Optimal (1-wp)`, các hàng còn lại có gap; bảng được tạo lại. (2) `experiment.jl`: lưu nghiệm của mọi lần chạy (`-run<k>-srpaths.json`), `verify_srpaths.py` đối chiếu theo `run == k`; bộ test đạt; áp dụng cho các seed khởi động sau thay đổi (từ seed 10 của setA-04 $t=0,1$; seed 9 đã khởi động trước thay đổi; seed 5–8 không có nghiệm lưu riêng). (3) Phát hiện: giá trị 0,50105 của setA-04 Bảng 1 (lần 4) không có nghiệm kiểm chứng đi kèm; cần chạy lại lần 4 sau khi chuỗi chính xong.

- **20/10 21:36** — Watchdog dừng setA-05 $t=0,1$ seed 10 (PID 26580, 11,7 GB) vì RAM trống 0,87 GB (< 1,5 GB); lúc đó ngoài tiến trình thực nghiệm còn khoảng 19 GB bị ứng dụng khác dùng. Seed 10 không có dòng CSV. Hiện setA-05 $t=0,1$ có 9 lần hợp lệ (seed 1–9; seed 7 Optimal 0,20499 trong 233 s, các lần còn lại Not Optimal 0,99999). Việc bù xếp lịch: `fill_followup_m1.sh` (setA-04 $t=0,1$ seed 6; setA-04 $t=0$ seed 4 chạy lại) rồi `fill_followup2_m1.sh` (setA-05 $t=0,1$ seed 10, cần RAM trống ≥ 12 GB).
