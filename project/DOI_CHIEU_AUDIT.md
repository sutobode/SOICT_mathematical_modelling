# Đối chiếu bản audit (OpenCode) với mã nguồn và kết quả thực tế

**Thời điểm:** Thứ Ba 20/10/2026, ~15:00. **Nguồn:** bản audit mà người dùng dán vào phiên làm việc (không có trong repo).
**Cách làm:** từng khẳng định của audit được đối chiếu với mã (`grep`, đọc code) hoặc với số liệu trong `orange/results/`. Cột "Đánh giá" là kết quả đối chiếu, không phải ý kiến.

---

## 1. Tổng hợp

| # | Khẳng định của audit | Đánh giá | Bằng chứng | Hành động |
|---|---|---|---|---|
| 1 | Có hai cách tính $r$ (đếm đường và ECMP từng chặng), khác nhau ở setA-18 và setA-20; nên dùng đường đi đếm theo `calculating_r.pdf` | **Đúng, và đã làm đúng như vậy** | `r_difference.csv`: chỉ setA-18 và setA-20 có cặp nút lệch (1 cặp mỗi thời kỳ). Các hàng `arc-pc` dùng công thức của thầy. | Không đổi. Báo cáo cần nêu rõ (đã có trong `BAO_CAO_KET_QUA_THUC_NGHIEM.md` mục 2.4). Thầy chưa trả lời câu hỏi này. |
| 2 | Instance lớn dùng bài toán thu hẹp (≤ 1 waypoint, tức ≤ 2 đoạn) trong khi $\text{maxSeg}=6$; "Optimal" chỉ đúng trong không gian thu hẹp | **Đúng; đã công khai** | Hàng `*` trong hai bảng; `BAO_CAO_KET_QUA_THUC_NGHIEM.md` mục 3.2, 8. Trên setA-04, 05 (nơi so được) mô hình thu hẹp trùng hoặc sát tối ưu (0,011 %). | Không đổi. Giữ nhãn `*` và câu giải thích. |
| 3 | Chưa có tối ưu từ điển thật; mục tiêu là $z+\varepsilon\sum x$; các hàm `lex_*` không được runner dùng | **Đúng** | `grep` trong `orange/src` và `orange/scripts`: `lex_refine`, `lex_second_stage!` chỉ có định nghĩa và export, không hàm nào của runner gọi chúng. | **Đã sửa tài liệu hôm nay:** báo cáo kết quả không còn nói bảng dùng `lex_refine`. Cài đặt đúng mục tiêu từ điển là việc tối ưu thêm (chưa làm). |
| 4 | Chỉ 8/40 hàng (P1 và P2) đủ 10 lần chạy | **Đúng** | Bảng 1: setA-01…05 (5 hàng); Bảng 2: setA-01, 02, 03 (3 hàng) = 8. Khi M1 chạy xong: +2 (setA-04, 05 ở $t=0,1$) = 10/40. | M1 đang chạy. Các hàng `*` (30/40) mới 1 lần: đã nêu ở báo cáo; chưa chạy lặp vì không có máy đủ RAM để chạy mô hình đầy đủ và chưa quyết định chạy lặp mô hình thu hẹp. |
| 5 | Script gộp lấy trung bình "các lần đang có", không ép đủ 10 | **Đúng** | `official_tables.jl` in cột `Runs` = số lần thực có; không có ngưỡng. | Giữ nguyên (trung thực hơn là che số lần). Báo cáo phải đọc cột `Runs`. |
| 6 | Trộn kết quả hai kiểu $r$ khi chọn "tốt nhất" | **Đúng về cấu trúc, không ảnh hưởng số liệu** | `best_known.jl` quét mọi file `setA-XX-wp-P<P>*.csv` kể cả không có hậu tố `-pc`; tất cả hàng `*` hiện lấy từ file không `-pc`. Nhưng với mọi cặp (cùng phương pháp, có cả hai kiểu $r$) đã kiểm tra, MLU **giống nhau** (kể cả setA-18, 20); với 18 instance còn lại hai kiểu $r$ trùng hẳn. | Ghi chú trong báo cáo: hàng `*` dùng $r$ ECMP, trùng $r$ của thầy ở mọi instance trừ setA-18, 20 (đã kiểm chứng bằng file `-pc`). Có thể giới hạn `best_known.jl` vào file `-pc` sau khi M1 chạy xong. |
| 7 | Cận dưới của hàm mục tiêu có phạt bị dùng như cận dưới của MLU thuần | **Đã xử lý trong code** | `best_known.jl`: cận dưới theo cung trừ $10^{-7}\cdot P\cdot 6$ (phạt tối đa), mô hình waypoint trừ $10^{-7}\cdot P$ | Không đổi. |
| 8 | Chưa hỗ trợ đa đồ thị thật | **Đúng, nhưng không ảnh hưởng SetA** | Cả 20 instance không có cung song song hay khuyên (đã kiểm tra); 10/20 file khai báo `multigraph: true` | Không đổi; nêu trong báo cáo. |
| 9 | "CPU time" thực ra là thời gian giải của HiGHS | **Đúng** | `experiment.jl` dùng `solve_time(model)` | **Đã sửa tài liệu:** báo cáo gọi đúng tên "thời gian giải"; cột tiêu đề của bảng vẫn là CPU time theo yêu cầu của thầy. |
| 10 | Mô hình theo cung (đại số) không có lỗi nghiêm trọng trên SetA | **Phù hợp với kiểm tra của nhóm** | test khớp ví dụ mẫu của đề và vét cạn; 93/93 nghiệm kiểm chứng độc lập | — |

---

## 2. Điểm audit thiếu hoặc chưa nêu

1. **Các lần chạy vượt giới hạn thời gian** (HiGHS vượt giới hạn tới ~2 lần: setA-05 $t=0,1$ seed 5 mất 7175 s; setA-04 $t=0,1$ seed 6 và 8 vượt xa). Đây là vấn đề cần ghi chú khi đọc cột thời gian; M1 đã thêm `hang_guard.py` (dừng lần chạy quá 7800 s).
2. **Hàng `arc-pc` của setA-04, 05 ở $t=0,1$ cho kết quả kém** (mô hình theo cung kẹt ở nút gốc); đã công khai kèm cột "Tốt nhất biết được".

## 3. Việc nên làm tiếp (theo ưu tiên, sau khi M1 chạy xong)

| Ưu tiên | Việc | Tác dụng |
|---|---|---|
| 1 | Ghi vào báo cáo: hàng `*` dùng $r$ ECMP (trùng $r$ của thầy trừ setA-18, 20) và mọi kết quả `*` chỉ tối ưu trong bài toán ≤ 1 waypoint | Tránh nhầm semantics |
| 2 | Giới hạn `best_known.jl` vào file `-pc` (hoặc ghi cột `r_mode`) | Gộp kết quả sạch hơn về mặt hình thức |
| 3 | Cài đặt mục tiêu từ điển thật (giải liên tiếp từng tầng) cho các instance nhỏ giải được bằng mô hình theo cung | Sát mục tiêu (5) của đề |
| 4 | Chạy lặp 10 lần các hàng `*` (đo thời gian) | Đủ "trung bình 10 lần" về hình thức |
