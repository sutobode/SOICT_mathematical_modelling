# Kế hoạch các giai đoạn đến mốc T4 (Thứ Tư 21/10/2026)

> Lập lúc 23:45 Thứ Hai 19/10. **Mốc cứng: xong hết code và thực nghiệm trước T4.** Hạn nộp báo cáo cho thầy: Chủ nhật 25/10 (báo cáo do người khác viết, dựa trên các tài liệu và kết quả ở đây).
> Nguyên tắc: **yêu cầu tối thiểu của thầy trước, cải tiến sau.**

## 0. Tình trạng lúc 23:45 (đã đo)

| | Dòng theo đề (`arc-pc`) | Số lần chạy hiện có | Còn thiếu để đủ 10 lần |
|---|---|---|---|
| **Bảng 1** ($t=0$, 1800 s) | setA-01, 02, 03, 05 | 10 | không |
| | setA-04 | 6 | 4 lần × 30 phút |
| | setA-06 đến 20 | mô hình theo cung không dựng được (quá lớn) | dùng nghiệm waypoint, dấu `*` |
| **Bảng 2** ($t=0,1$, 3600 s) | setA-01 | 10 | không |
| | setA-02 | 4 | 6 lần × 33 đến 60 phút |
| | setA-03 | 5 | 5 lần × 5 phút |
| | setA-04 | 2 | 8 lần × 61 phút (chạy tuần tự, mỗi lần ~8 GB RAM đỉnh) |
| | setA-05 | 0 (bị bỏ qua vì RAM) | thử chạy sau setA-04, mỗi lần ~11 GB RAM |
| | setA-06 đến 20 | không dựng được | nghiệm waypoint; **setA-19 chưa có** (đang chạy) |

Kiểm chứng độc lập (Python): 91 file nghiệm, 0 vi phạm. Máy: 31,6 GB RAM; các ứng dụng khác chiếm ~10 GB, nên chỉ chạy được **một** tiến trình setA-04 ở $t=0,1$ mỗi lần.

---

## Phase 1 — Yêu cầu tối thiểu của thầy (hôm nay, hạn 00:30)

**Tiêu chí hoàn thành:** hai bảng đủ 20 dòng, mỗi dòng có đủ cột thầy yêu cầu (đỉnh, cung, demand, giá trị tối ưu/tốt nhất, CPU time của `optimize!`, status, gap nếu chưa tối ưu, số nút B&B, số lần chạy), có nguồn và nhãn rõ; môi trường chạy; mã nguồn và test; kiểm chứng; truy vết.

| # | Việc | Trạng thái | Ai |
|---|---|---|---|
| 1.1 | Mô hình theo đề, phần Data, $r$ theo công thức của thầy | xong | mình |
| 1.2 | Bảng 1 đủ 20 dòng | xong (số lần chạy hiện có) | mình |
| 1.3 | Bảng 2: dòng setA-19 (đường nhanh: sinh cột thời kỳ đầu + LNS) | đang chạy, dự kiến 23:45–00:15 | mình |
| 1.4 | Tạo lại `best_known.csv`, hai bảng chính thức, `verification.csv` (chạy lại cho file mới) | sau 1.3 | mình |
| 1.5 | Làm mới manifest (SHA-256, commit mã nguồn, lệnh đã chạy), zip sao lưu, commit | sau 1.4 | mình |
| 1.6 | Báo bạn: danh sách file giao nộp và các lưu ý trung thực | sau 1.5 | mình |

**Giới hạn đã chấp nhận ở Phase 1:** dòng chậm (setA-04 ở hai bảng, setA-02 ở $t=0,1$) chưa đủ 10 lần; setA-05 ở $t=0,1$ chưa chạy. Cột `Runs` ghi đúng số lần. Phase 1b bù phần này.

---

## Phase 1b — Đưa các dòng theo đề lên đủ 10 lần (đêm nay đến Thứ Ba)

Các tiến trình đang chạy tự động; số liệu tự gộp vào bảng khi tạo lại (`official_tables.jl`).

| # | Việc | Số lần còn lại | Dự kiến xong | Ghi chú |
|---|---|---|---|---|
| 1b.1 | Bảng 2 / setA-03 (lần 6 đến 10) | 5 | ~00:30 Thứ Ba | nhẹ |
| 1b.2 | Bảng 1 / setA-04 (lần 7 đến 10) | 4 | ~02:00 Thứ Ba | ~2 GB RAM |
| 1b.3 | Bảng 2 / setA-02 (lần 5 đến 10) | 6 | ~04:00–06:00 Thứ Ba | thời gian phụ thuộc tải máy |
| 1b.4 | Bảng 2 / setA-04 (lần 3 đến 10, **tuần tự**) | 8 | ~08:00–09:00 Thứ Ba | **đường găng**; không chạy 2 tiến trình cùng lúc (đã thử, bị watchdog dừng) |
| 1b.5 | Bảng 2 / setA-05 bằng mô hình theo đề (10 lần × ~65 phút, ~11 GB RAM mỗi lần) | 10 | ~20:00 Thứ Ba nếu bắt đầu 09:00 | **điều kiện: RAM trống ≥ 14 GB sau setA-04**; nếu không đủ, giữ dòng waypoint `*` |
| 1b.6 | Làm mới bảng, manifest, zip sau mỗi mốc | | mỗi mốc | tự động qua sao lưu 30 phút |

**Quy tắc cắt:** nếu đến **22:00 Thứ Ba** dòng nào chưa đủ 10 lần, chốt với số lần đã xong và ghi rõ trong cột `Runs`.

---

## Phase 1c — Đo lại thời gian sạch (Thứ Ba, sau khi Phase 1b xong, máy không tải)

Lý do: các lần chạy bổ sung chạy song song nên `solve_time` bị kéo dài (setA-05: 172 s khi ít tải, ~330 s khi tải nặng) và trạng thái Optimal/Not Optimal có thể đổi (setA-02 ở $t=0,1$). Cột "CPU time" của thầy yêu cầu thời gian của riêng `optimize!`.

| # | Việc | Ước lượng |
|---|---|---|
| 1c.1 | Chạy lại **một mình** (không chạy gì khác) các dòng nhanh: Bảng 1 / setA-01, 02, 03, 05 (10 lần) và Bảng 2 / setA-01, 03 | ~1,5 giờ |
| 1c.2 | Tạo bảng "thời gian sạch" riêng, đối chiếu với bảng chính | 15 phút |
| 1c.3 | Nếu còn thời gian (không bắt buộc): chạy lại setA-02 ở $t=0,1$ một mình (10 × ~33 phút) | ~6 giờ, chỉ nếu máy rảnh |

---

## Phase 2 — Cải tiến chất lượng (không bắt buộc, chỉ làm khi Phase 1b đang chờ và không chiếm RAM)

| # | Việc | Giá trị | Chi phí | Ưu tiên |
|---|---|---|---|---|
| 2.1 | **Sửa nhãn trạng thái** của các dòng waypoint ở Bảng 2: hiện ghi "Not Optimal\*" cho cả những dòng MILP đã tối ưu trên tập cột sinh ra; đổi thành "Optimal (restricted)" / "Not certified" | trung thực, dễ đọc | thấp (script) | cao |
| 2.2 | LNS cho các dòng Bảng 2 có nghiệm yếu (ví dụ setA-18 = 1,0, setA-07, setA-20 gần mức cơ sở): kiểm tra có phải điểm nghẽn thật hay chưa tối ưu | có thể cải thiện MLU | trung bình | trung bình |
| 2.3 | Cận dưới chặt hơn cho $P=2$ (đưa ngân sách vào định giá khi sinh cột, hoặc Lagrange) | thu hẹp gap | cao | thấp |
| 2.4 | Tinh chỉnh theo thứ tự từ điển (`lex_refine`) cho các nghiệm cuối, xuất vector tải sắp xếp | sát mục tiêu (5) của đề | trung bình | thấp |
| 2.5 | Kiểm tra mô hình hai waypoint ở nhiều instance hơn (đã có 5 instance cho thấy một waypoint đủ) | tăng độ tin cậy của lập luận | thấp | thấp |
| 2.6 | Sửa 10 lỗi nhỏ đã hoãn (xem `.superpowers/.../progress.md`), ví dụ heuristic dừng khi nhiều cung cùng tải lớn nhất | chất lượng mã | thấp | thấp |

**Điều kiện:** mọi việc Phase 2 chạy với RAM còn dư ≥ 4 GB và **không làm chậm** các tiến trình Phase 1b (đo bằng STATUS.md). Không chạy Phase 2 trong lúc setA-05 ở $t=0,1$ đang chạy.

---

## Phase 3 — Hoàn tất và bàn giao (sáng Thứ Tư, hạn trước trưa)

| # | Việc | Ai |
|---|---|---|
| 3.1 | Chạy lại kiểm tra độc lập (Python) cho toàn bộ file nghiệm mới | mình |
| 3.2 | Tạo lại `best_known.csv`, `table_official_P1/P2`, bảng thời gian sạch, `verification.csv`, MANIFEST | mình |
| 3.3 | Cập nhật `orange/README.md`, `README_KET_QUA.md`, `BAI_TOAN_FINAL.md` (nếu có số liệu thay đổi) | mình |
| 3.4 | Dừng toàn bộ tiến trình nền (watchdog, keep-awake, hẹn giờ), làm sạch thư mục tạm | mình |
| 3.5 | Zip cuối cùng + commit toàn bộ kết quả lên `feature/tasr` | mình |
| 3.6 | **Quyết định của bạn:** push `feature/tasr`; merge vào `main` (nhánh Final); dọn các dòng `Co-Authored-By: Claude` cũ trong lịch sử `main` bằng `push --force` (mình tạo nhánh sao lưu trước và hỏi lại ngay trước khi force-push) | bạn |
| 3.7 | Gửi gói bàn giao (zip + README_KET_QUA + BAI_TOAN_FINAL + hai bảng) cho người viết báo cáo | bạn |
| 3.8 | Viết báo cáo ≤ 10 trang (Giới thiệu, Mô hình, Thực nghiệm) | người khác |
| 3.9 | Nêu rõ trong báo cáo các sai khác so với yêu cầu thầy (mục 4 dưới đây) | người viết báo cáo |

---

## Lịch theo giờ

| Khi nào | Việc |
|---|---|
| T2 đêm 23:45–00:30 | hoàn tất **Phase 1** (bảng đủ 40 dòng, kiểm chứng, manifest, zip, commit) |
| T2 đêm đến T3 08:00 | Phase 1b chạy tự động (setA-03, setA-04 $t=0$, setA-02 xong dần); mình kiểm tra mỗi 30 phút; nếu bạn ngủ, vẫn tự chạy |
| T3 08:00–09:00 | setA-04 $t=0,1$ xong; quyết định thử setA-05 $t=0,1$ (cần RAM) |
| T3 09:00–20:00 | setA-05 $t=0,1$ (nếu đủ RAM); song song Phase 2 nhẹ (2.1, 2.2) nếu RAM cho phép |
| T3 20:00–22:00 | **quy tắc cắt Phase 1b**; Phase 1c (đo lại thời gian sạch, máy không tải) |
| T4 sáng | Phase 3 (kiểm chứng cuối, bảng cuối, manifest, zip, commit, bàn giao) |
| T4 trước trưa | **xong hết code và thực nghiệm** |

## 4. Những điểm lệch so với yêu cầu thầy (phải nêu trong báo cáo)

1. Mô hình theo đề chỉ có dữ liệu cho instance 01–05 ($t=0$) và 01–04 ($t=0,1$); các instance lớn hơn không dựng được trong RAM (5 triệu đến gần 1 tỷ biến). Dòng thay thế là nghiệm của **mô hình waypoint** (một waypoint mỗi demand, dấu `*`), hợp lệ cho bài toán gốc, đã kiểm chứng độc lập.
2. Số lần chạy: 10 lần cho dòng nhanh; dòng chậm chạy đủ 10 lần nếu kịp theo quy tắc cắt, nếu không ghi số lần thực tế.
3. Không dùng chính notebook Pluto (Pluto v2 từ chối 10/20 file vì cờ `multigraph`); đồ thị dựng ra giống hệt.
4. $r$ theo công thức của thầy; trùng ECMP của đề ở 18/20 instance (`r_difference.csv`).
5. Mục tiêu là min MLU (mức đầu của thứ tự từ điển).
6. Thời gian đo là đồng hồ thực, HiGHS một luồng; các lần bổ sung chạy dưới tải song song (xem Phase 1c).
7. HiGHS không tôn trọng giới hạn thời gian ở mô hình rất lớn khi bật presolve; đã tắt presolve cho mô hình trên 1,2 triệu biến.
8. Máy ngủ 18:40–19:10 ngày 19/10 làm gián đoạn một số lần chạy (không ảnh hưởng MLU).

## 5. Rủi ro và phương án dự phòng

| Rủi ro | Phương án |
|---|---|
| Hết RAM, watchdog dừng tiến trình | watchdog chỉ dừng tiến trình **ít CPU nhất** (bảo vệ lần chạy dài); các tiến trình mới khởi động tự chờ RAM trống ≥ 10 GB |
| Máy ngủ | `keep_awake.ps1` đang chạy; bạn cắm sạc, không gập nắp |
| setA-05 ở $t=0,1$ không chạy được (RAM) | giữ dòng waypoint `*` và ghi trung thực |
| setA-04 ở $t=0,1$ vượt quy tắc cắt | chốt số lần đã xong (ít nhất 2 lần hiện có) |
| Số liệu thời gian bị nhiễu | Phase 1c, và ghi chú trong tài liệu |
| Mất file kết quả | sao lưu zip mỗi 30 phút ngoài git (`C:\Users\X1\Project\SOICT_results_backup`), commit định kỳ, manifest SHA-256 |

## 6. Việc của bạn (tóm tắt)

1. Giữ máy thức, cắm sạc, không gập nắp, không chạy việc nặng (đặc biệt trong lúc setA-04 và setA-05 ở $t=0,1$ chạy).
2. Sáng Thứ Ba: cho mình biết còn giải phóng được RAM không (để thử setA-05 ở $t=0,1$).
3. Sáng Thứ Tư: quyết định push, merge `main`, dọn lịch sử; gửi gói bàn giao cho người viết báo cáo.
