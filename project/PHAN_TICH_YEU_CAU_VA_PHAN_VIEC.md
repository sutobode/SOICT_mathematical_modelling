# Yêu cầu của thầy → đã làm gì → còn thiếu gì → ai làm được

**Thời điểm:** Thứ Ba 20/10/2026, ~09:00. Mốc nội bộ: xong trước **T4 (Thứ Tư 21/10)**. Hạn nộp thầy: **Chủ nhật 25/10**.
**Nguồn yêu cầu:** `project/readme` của thầy (Step 1–9 + phần báo cáo). Không có gì khác ngoài file này.

---

## 1. Yêu cầu của thầy, từng bước

| Bước / mục | Yêu cầu | Trạng thái | Bằng chứng | Còn thiếu |
|---|---|---|---|---|
| Step 1 | Đọc và hiểu đề | ✅ Xong | `project/BAI_TOAN_FINAL.md` | — |
| Step 2 | Dựng đồ thị $G$ ở $t=0$ từ JSON (script Pluto) | ✅ Xong, **khác cách** | `orange/src/io.jl`; test đọc cả 20 instance | Script Pluto của thầy **báo lỗi trên 10/20 instance** (`multigraph: true`), nên code đọc JSON trực tiếp; đã kiểm tra không có cung song song. **Phải nói rõ điều này trong báo cáo.** |
| Step 3 | Tính $r[i,j,a,0]$ theo `calculating_r.pdf` | ✅ Xong | `src/ecmp.jl` (chế độ `:pathcount`); khác ECMP của đề ở 2/20 instance | Phần giải thích hai định nghĩa $r$ trong báo cáo |
| Step 4 | Mục Data: $r$, $c(a)$, $v(d,0)$, MaxSeg | ✅ Xong | `src/io.jl`, `src/ecmp.jl` | Viết thành mục Data trong báo cáo |
| Step 5 | Mô hình chỉ cho $t=0$ (không ràng buộc ngân sách) | ✅ Xong | `src/model.jl`, tham số `P=1` | — |
| Step 6 | Thực nghiệm $t=0$, 1800 s, bảng 20 instance | 🟡 **Gần xong** | `orange/results/table_official_P1.md` | Xem mục 2 (A2) |
| Step 7 | Đồ thị và tham số ở $t=1$ | ✅ Xong | `src/io.jl`, `src/ecmp.jl` ($r$ trên $G_1$) | — |
| Step 8 | Mở rộng mô hình sang $t=0,1$ + ngân sách | ✅ Xong | `src/model.jl`, `P=2` | — |
| Step 9 | Thực nghiệm 3600 s, bảng 20 instance | 🟡 **Gần xong** | `orange/results/table_official_P2.md` | Xem mục 2 (A1, A2). Đề ghi "only time period 0" (lỗi đánh máy); mình hiểu là $t=0,1$ — **cần nêu lựa chọn này trong báo cáo** |
| Báo cáo: Giới thiệu | bối cảnh, động lực, mô tả bài toán | 🔴 Chưa viết | `report/sections/01_intro.tex` mới 4 dòng | Viết |
| Báo cáo: Mô hình toán | Data, biến, mục tiêu, ràng buộc, giải thích chi tiết | 🔴 Chưa viết | `report/sections/02_model.tex` mới 26 dòng | Viết (nguồn: `BAI_TOAN_FINAL.md` mục 2–5) |
| Báo cáo: Thực nghiệm | mô tả instance, **môi trường chạy**, bảng **trung bình 10 lần** | 🔴 Chưa viết | `03_experiments.tex` mới 26 dòng; bảng `.tex` đã tạo sẵn | Viết (nguồn: `BAO_CAO_KET_QUA_THUC_NGHIEM.md` mục 4–5) |
| Báo cáo: ≤ 10 trang | giới hạn độ dài | ⚠️ | — | Kiểm tra sau khi viết (bảng 20 hàng × 2 chiếm chỗ) |

Các cột bảng thầy yêu cầu (đỉnh, cung, demand, MLU, CPU time chỉ của `optimize!`, trạng thái, gap, số nút B&B) đều đã có trong cả hai bảng.

---

## 2. Những chỗ còn thiếu, theo mức độ

### A. Bắt buộc theo đề

| # | Thiếu | Chi tiết | Ước tính |
|---|---|---|---|
| **A1** | **Trung bình 10 lần cho Bảng 2, setA-04 và setA-05** | setA-04 mới 4/10, setA-05 mới 5/10. M1 đang chạy nốt (6 + 5 lần, tuần tự, mỗi lần ≈ 1 giờ), dự kiến xong ~20:00. | ~11 giờ máy M1 |
| **A2** | **Trung bình 10 lần cho các hàng setA-06…20 (cả hai bảng)** | Các hàng này hiện chỉ **1 lần** chạy, và dùng mô hình waypoint (`*`), không phải mô hình của thầy. `run_wp.jl` **chưa có tham số số lần/seed**; muốn có 10 lần phải sửa script trước (≈ 30 phút), rồi chạy (hàng nhanh: giây đến phút; hàng chậm: 300–1800 s/lần). | Code 30 phút + chạy vài giờ |
| **A3** | **Báo cáo ≤ 10 trang** | Chưa viết. Đây là sản phẩm nộp, và chưa có. | 1 ngày người |
| **A4** | **Mô tả môi trường chạy** trong báo cáo | Đã có dữ liệu (i7-1270P, 31,6 GB RAM, Windows 11, Julia 1.13.1, JuMP 1.32.1, HiGHS 1.26.0, `threads=1`). Mỗi máy M2/M3 nếu chạy phải có file `environment-<tên>.txt`. | Vài phút |

### B. Nên có (giảm rủi ro bị thầy hỏi)

| # | Thiếu | Chi tiết |
|---|---|---|
| **B1** | **Hàng `*` không phải mô hình của thầy** | Cần một đoạn giải thích trung thực trong báo cáo: vì sao (RAM), và bằng chứng waypoint ≈ tối ưu (setA-05 trùng 8 chữ số; setA-04 trong 0,011 %). Đã có sẵn nội dung ở `BAO_CAO_KET_QUA_THUC_NGHIEM.md` mục 3.2. |
| **B2** | **Tái lập kết quả trên máy khác** | Chưa ai ngoài M1 chạy lại code. Một người chạy lại `runtests.jl` và vài instance nhỏ để xác nhận kết quả không phụ thuộc máy. |
| **B3** | **Thời gian sạch** | Một số hàng nhanh bị đo khi máy chạy song song nên CPU time bị méo (setA-02/03 $t=0,1$ đổi nhãn Optimal ↔ Not Optimal). Có thể chạy lại khi máy rảnh. |
| **B4** | **Nhãn trạng thái hàng `*`** | Hiện "Optimal\*" / "Not Optimal\*"; nên đổi thành "Optimal (restricted)" hoặc chú thích rõ trong bảng. |

### C. Tối ưu thêm (sau khi A, B xong)

Cải thiện các hàng yếu $t=0,1$ (setA-18 = 1,0; setA-07; setA-20), tinh chỉnh mục tiêu từ điển, sửa heuristic. **Không cần cho yêu cầu tối thiểu.**

---

## 3. Gói việc và chỗ M2, M3 có thể tham gia

Nguyên tắc: **không ai sửa cùng một file** (tránh xung đột git); mỗi gói có chủ sở hữu file riêng.

| Gói | Việc | Ai làm | Điều kiện | Phụ thuộc | Ước tính |
|---|---|---|---|---|---|
| **WP1** (A1) | setA-04 $t=0,1$ lần 5–10; setA-05 $t=0,1$ seed 6–10 | **M1 (đang chạy)** | Máy M1 | — | ~11 giờ |
| **WP2a** | Thêm tham số số lần/seed cho `run_wp.jl` (và `lns`), ghi file có hậu tố riêng như `run_experiments.jl` | **M1** | Biết code | — | ~30 phút |
| **WP2b** (A2) | Chạy 10 lần các hàng setA-06…20, $t=0$ **và** $t=0,1$ | **chưa giao** (đề xuất M2/M3 **sau** khi xong gói O2/O3 ở `DE_XUAT_CAI_TIEN_TOI_UU.md`) | sau WP2a; mỗi hàng đủ 10 lần trên cùng một máy; ghi file có hậu tố `-rA-B` (không trùng tên với file của O2/O3) | WP2a | vài giờ mỗi người |
| **WP3** (A3) | Viết **Giới thiệu + Mô hình toán** (Data, biến, mục tiêu, ràng buộc, hai định nghĩa $r$, giải thích Step 2 khác Pluto) | **M2** | Biết LaTeX | Nguồn: `BAI_TOAN_FINAL.md` | ~4–5 giờ |
| **WP4** (A3, A4) | Viết **Thực nghiệm** (mô tả instance, môi trường, bảng, nhận xét kết quả, hạn chế) + kiểm tra **≤ 10 trang** | **M3** | Biết LaTeX | Nguồn: `BAO_CAO_KET_QUA_THUC_NGHIEM.md`; bảng cuối sau WP1, WP2b | ~4–5 giờ (chốt số sau khi bảng xong) |
| **WP5** (B2) | Tái lập: clone repo, chạy `runtests.jl`, chạy setA-01…03 $t=0$ và so với bảng | **M3 hoặc M2** (ai có máy rảnh) | Máy ≥ 16 GB | — | ~1 giờ |
| **WP6** (B1) | Kiểm tra chéo cách tính $r$: đọc `calculating_r.pdf`, tính tay một ví dụ nhỏ, so với `ecmp.jl`, ghi thành đoạn giải thích cho báo cáo | **M2** | — | — | ~1–2 giờ |
| **WP7** | Gộp kết quả `results/m2`, `results/m3` → tạo lại bảng → kiểm chứng → manifest → squash merge vào `main` | **M1** | Sau WP1, WP2b | WP1, WP2b | ~1 giờ |
| **WP8** (C) | Cải thiện hàng yếu, đổi nhãn (B4), chạy lại hàng nhanh (B3) | **M1** | Máy rảnh sau WP1 | WP1 | tuỳ |

### Đường găng (tối thiểu để thầy chấp nhận)

1. **WP1** (M1, ~20:00 hôm nay) và **WP2a → WP2b** (hôm nay/sáng mai): bảng đủ trung bình 10 lần.
2. **WP3 + WP4** (M2, M3, **song song ngay từ bây giờ**): báo cáo có thể viết khung và phần không phụ thuộc số liệu (Giới thiệu, Mô hình, môi trường) trước; chỉ **điền bảng** sau.
3. **WP7**: chốt bảng, cập nhật báo cáo, nộp.

M2 và M3 **không phải chờ M1**: WP3, WP4 (khung), WP5, WP6 bắt đầu được ngay.

### Cách chia khi M2 hoặc M3 chỉ có máy yếu (< 16 GB RAM)

- WP2b nặng RAM ở vài hàng → chuyển các hàng đó cho M1 (sau WP1).
- WP3, WP4, WP6 không cần máy mạnh → vẫn làm được.

---

## 4. Rủi ro cần biết trước

1. **Báo cáo là phần chưa có gì và nằm trên đường găng.** Nếu M2/M3 không viết, hạn nộp bị ảnh hưởng hơn là thiếu số lần chạy.
2. **Chạy 10 lần các hàng `*` có thể không đổi kết quả** (bài toán thu hẹp gần như tất định): chỉ đo thời gian. Vẫn nên làm vì đề yêu cầu trung bình 10 lần, nhưng ưu tiên **thấp hơn báo cáo**.
3. **Trộn máy khi tính trung bình** làm CPU time khó so sánh: mỗi hàng nên chạy hết trên một máy và ghi rõ máy nào.
4. **Hai hàng `arc-pc` ở $t=0,1$ cho kết quả kém** (setA-04, 05) — phải trình bày cùng cột "tốt nhất biết được", nếu không thầy sẽ thấy MLU 0,99999 mà không có giải thích.
5. **Quy tắc git của M2/M3:** `START_HERE.md` chỉ cho phép M2/M3 dùng một số lệnh git nhất định và không sửa file đã theo dõi. **WP3, WP4 sửa file báo cáo**, nên cần bổ sung hướng dẫn (nhánh riêng `report/m2`, `report/m3`, mỗi người một file `.tex`) trước khi giao.

---

## 5. Phân công hiện hành và đề xuất còn lại

**Đã giao (hiệu lực ngay, ghi trong `START_HERE.md`):** M2 và M3 chạy các thử nghiệm cải tiến tối ưu O2/O3 (`project/DE_XUAT_CAI_TIEN_TOI_UU.md`); M1 chạy nốt WP1. **Các gói còn lại dưới đây là đề xuất, chưa giao.** Khi giao, phải chọn instance/tập file khác với O2/O3 để không trùng:

- M2: **WP3** (Giới thiệu + Mô hình), **WP6** (kiểm tra $r$), rồi **WP2b** nửa đầu (setA-06…13) sau khi M1 sửa `run_wp.jl`.
- M3: **WP4** (Thực nghiệm + ≤ 10 trang), **WP5** (tái lập), rồi **WP2b** nửa sau (setA-14…20).
- M1: WP1 (đang chạy), WP2a (làm ngay), WP7, WP8.

Nếu đồng ý, bước kế tiếp là: (1) M1 sửa `run_wp.jl` (WP2a); (2) M1 bổ sung `START_HERE.md` cho WP2b, WP3, WP4, WP5, WP6 theo cùng kiểu từng bước.
