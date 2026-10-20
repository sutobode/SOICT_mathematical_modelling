# Phân công nhóm (3 thành viên) — làm song song, không chờ nhau

> **CẬP NHẬT 20/10 ~10:00 — PHÂN CÔNG HIỆN HÀNH (thay thế phân công cũ ở dưới):** M1 chạy **toàn bộ** các lần còn thiếu của setA-04 và setA-05 ($t=0,1$); M2 và M3 chạy **thử nghiệm cải tiến tối ưu** trên các instance riêng (xem `START_HERE.md` mục 1 và 10, và `project/DE_XUAT_CAI_TIEN_TOI_UU.md`). Các bảng phân công bên dưới là bản gốc, **chỉ để tham khảo, không làm theo**.

> Lập lúc 23:50 Thứ Hai 19/10. Mốc cứng: **xong hết trước Thứ Tư 21/10 (T4)**; hạn nộp thầy: Chủ nhật 25/10.
> Nguyên tắc: mỗi người **sở hữu file riêng**, nên không xung đột khi dùng git; số liệu cập nhật **tự động** khi máy chạy xong, không ai phải chờ ai.

## 1. Cái gì đã sẵn sàng NGAY BÂY GIỜ (không còn nghẽn)

| Tài liệu | Dùng để | Đã ổn định? |
|---|---|---|
| `project/BAI_TOAN_FINAL.md` | hiểu bài toán, mô hình, dữ liệu, cách tính $r$ | **ổn định**, không đổi nữa |
| `orange/README.md` | mã nguồn, cách chạy, các quyết định thiết kế, đối chiếu yêu cầu của thầy (mục 5e) | ổn định |
| `orange/results/README_KET_QUA.md` | đọc kết quả: tên file, cột CSV, 10 lưu ý trung thực | ổn định |
| `project/KE_HOACH_CAC_GIAI_DOAN.md` | tình trạng thực nghiệm, các điểm lệch so với yêu cầu thầy | cập nhật theo tiến độ |
| `report/report.tex` + `report/sections/*.tex` | khung báo cáo đã **tách thành từng file** và biên dịch được (4 trang) | khung ổn định |
| `report/table_official_P1.tex`, `table_official_P2.tex` | hai bảng kết quả chính thức | **số liệu tự cập nhật** (xem mục 3) |
| `orange/results/*-loads.csv` | dữ liệu vẽ biểu đồ tải (trước/sau tối ưu) | có sẵn cho nhiều instance |
| `orange/results/MANIFEST.md` | truy vết: lệnh đã chạy, môi trường, SHA-256 | ổn định |

## 2. Chia việc

| Thành viên | Vai trò | File sở hữu | Việc | Có thể xong khi nào |
|---|---|---|---|---|
| **A** | **Mô hình** | `report/sections/01_intro.tex`, `02_model.tex` | Viết lại cho hoàn chỉnh phần Giới thiệu (bối cảnh Orange/Segment Routing, động cơ, mô tả T-ASR) và phần Mô hình toán (Data, Biến, Mục tiêu, Ràng buộc có giải thích chi tiết, ví dụ toy). Nguồn: `BAI_TOAN_FINAL.md` mục 1–4. Giải thích rõ: $r$ theo ECMP và theo công thức của thầy (trùng ở 18/20 instance), mục tiêu min MLU. | **hôm nay** (không phụ thuộc số liệu) |
| **B** | **Thực nghiệm** | `report/sections/03_experiments.tex`, `report/figures/` | Mô tả instance (bảng quy mô SetA: `BAI_TOAN_FINAL.md` mục 5.3), môi trường chạy (`environment.txt`), giao thức (giới hạn thời gian, số lần chạy, HiGHS một luồng), đặt hai bảng chính thức, **vẽ biểu đồ tải** từ `*-loads.csv` (ví dụ setA-01, 05, 13), viết nhận xét và mục "Deviations from the instructions". | khung và biểu đồ: **hôm nay**; nhận xét cuối: sau khi bảng chốt (sáng Thứ Tư) |
| **C** | **Kiểm tra và hoàn thiện** | `report/sections/00_checklist.md` (ghi chú), tài liệu tham khảo, tiêu đề/tóm tắt | Đối chiếu từng con số trong báo cáo với CSV (`table_official_*`, `best_known.csv`) và `MANIFEST`; kiểm tra trung thực các điểm lệch so với thầy (mục 4 của `KE_HOACH_CAC_GIAI_DOAN.md`); đếm trang (≤ 10); tài liệu tham khảo (RFC 8402, đề Challenge ROADEF 2026, HiGHS, JuMP); đọc lại và sửa tiếng Anh/Việt; chuẩn bị nộp. | đọc kiểm liên tục; bản cuối sau khi A, B xong |

**Người điều phối (bạn):** chỉ cần (1) gửi gói bàn giao cho 3 bạn (mục 4), (2) trả lời câu hỏi, (3) quyết định merge `main`.

## 3. Số liệu tự cập nhật — không ai phải chờ

Hai bảng trong báo cáo được **sinh tự động** từ kết quả thực nghiệm:

- `report/table_official_P1.tex`, `report/table_official_P2.tex` được tạo lại bằng `julia orange/scripts/official_tables.jl`.
- Báo cáo chỉ dùng `\input{table_official_P1}` nên **chỉ cần biên dịch lại** là có số mới (đừng sửa tay hai file `.tex` này).
- Bảng đang ở trạng thái "Phase 1" (đủ 20 dòng, số lần chạy hiện có). Các dòng chậm sẽ tự có thêm lần chạy đến sáng Thứ Ba (xem cột Runs).
- Mình (trợ lý) làm mới bảng sau mỗi mốc và báo lại; các bạn lấy bản mới bằng `git pull` (hoặc nhận gói zip mới) rồi biên dịch lại.

## 4. Gói bàn giao (bạn gửi cho 3 bạn)

1. Cách 1 (khuyên dùng): push nhánh `feature/tasr` lên GitHub rồi 3 bạn `git clone` + `git checkout feature/tasr` (cần bạn đồng ý push; nhánh `main` giữ nguyên là Final).
2. Cách 2: gửi file zip trong `C:\Users\X1\Project\SOICT_results_backup\` (bản mới nhất `ket_qua_*.zip`, chứa kết quả + tài liệu) kèm thư mục `report/`.

Mỗi bạn chỉ **sửa file của mình** (cột "File sở hữu"). Cần biên dịch báo cáo: MiKTeX/TeX Live (gói `booktabs`, `pgfplots`, `amsmath`), lệnh `pdflatex report.tex` hai lần trong thư mục `report/`.

## 5. Lịch song song

| Khi nào | A | B | C | Mình (trợ lý) |
|---|---|---|---|---|
| T3 sáng | viết xong phần 1, 2 | mô tả instance, môi trường, giao thức; vẽ biểu đồ | lập danh sách đối chiếu; tài liệu tham khảo | thực nghiệm chạy, báo mỗi 30 phút |
| T3 chiều | rà soát với C | nhận xét sơ bộ trên bảng hiện có | đối chiếu số liệu bảng tạm | cập nhật bảng, kiểm chứng độc lập |
| T3 tối | — | — | — | quy tắc cắt 22:00, đo lại thời gian sạch (Phase 1c) |
| T4 sáng | xem lần cuối | **chốt nhận xét theo bảng cuối** | đối chiếu số liệu cuối, đếm trang | bảng cuối, manifest, zip, bàn giao |
| T4 trước trưa | | | | **xong hết code và thực nghiệm** |

## 6. Điều phải nêu trung thực trong báo cáo (C kiểm tra)

1. Mô hình theo đề chỉ có số liệu cho instance 01–05 ($t=0$) và 01–04 ($t=0,1$); các instance còn lại dùng mô hình waypoint (dấu `*`), hợp lệ cho bài toán gốc, đã kiểm chứng độc lập.
2. Số lần chạy ghi trong cột `Runs` (10 lần cho dòng nhanh; dòng chậm đủ 10 lần nếu kịp).
3. Không dùng chính notebook Pluto (đồ thị dựng giống hệt).
4. $r$ theo công thức của thầy; trùng ECMP của đề ở 18/20 instance.
5. Mục tiêu min MLU (mức đầu của thứ tự từ điển).
6. Thời gian là đồng hồ thực, HiGHS một luồng; các lần bổ sung chạy dưới tải song song nên thời gian dài hơn.
7. HiGHS không tôn trọng giới hạn thời gian khi bật presolve ở mô hình rất lớn; đã tắt presolve cho mô hình trên 1,2 triệu biến.
8. Máy ngủ 18:40–19:10 ngày 19/10 làm gián đoạn một số lần chạy (không ảnh hưởng MLU).
