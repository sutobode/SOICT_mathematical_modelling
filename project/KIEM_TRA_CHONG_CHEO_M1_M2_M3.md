# Kiểm tra chồng chéo (overlap) và xung đột (conflict) giữa M1, M2, M3

**Thời điểm:** Thứ Ba 20/10/2026, ~10:30. **Người đọc:** người dùng/điều phối (M1). M2 và M3 chỉ cần `HUONG_DAN_M2_M3_FINAL.md`.
**Kết luận ngắn:** **không có chồng chéo và không có xung đột** trong phân công hiện hành (đã kiểm tra bằng đối chiếu tên file, đối chiếu các tài liệu và chạy thử từ đầu đến cuối). Trong lúc kiểm tra đã tìm và sửa 1 lỗi và bổ sung 2 chỗ còn thiếu (mục 4).

---

## 1. Phân công hiện hành

| Bên | Máy | Việc | File kết quả |
|---|---|---|---|
| **M1** | máy M1 | setA-04 $t=0,1$ lần 5–10, rồi setA-05 $t=0,1$ seed 6–10 (script `fill_missing_m1.sh`, tuần tự); sau đó gộp, kiểm chứng, merge | `setA-04-P2-pc-r5-5.csv` … `r10-10`; `setA-05-P2-pc-r6-6.csv` … `r10-10`; log `log-pc-P2-0X-rK-K.txt` |
| **M2** | máy M2 | `run_wp.jl` ... (cg, pc, lns 900): setA-06, 09, 11, 12 (P=2); setA-10, 13 (P=1) | `setA-{06,09,11,12}-wp-P2-cg-pc-lns*`, `setA-{10,13}-wp-P1-cg-pc-lns*`, `log-opt-*` |
| **M3** | máy M3 | tương tự: setA-18, 14, 15 (P=2); setA-14 (P=1); tuỳ chọn setA-19 (P=1) | `setA-{18,14,15}-wp-P2-cg-pc-lns*`, `setA-14-wp-P1-cg-pc-lns*`, `setA-19-wp-P1-cg-pc-lns*` (tuỳ chọn), `log-opt-*` |

## 2. Kết quả kiểm tra

### 2.1. Chồng chéo về việc (cùng một instance bị hai bên chạy)

| Cặp | Kết quả |
|---|---|
| M2 ∩ M3 (theo (P, instance)) | **Rỗng.** M2: (2,6) (2,9) (2,11) (2,12) (1,10) (1,13). M3: (2,18) (2,14) (2,15) (1,14) (+ tuỳ chọn (1,19)). |
| M1 ∩ M2, M1 ∩ M3 | **Rỗng.** M1 chỉ chạy mô hình theo cung của setA-04 và setA-05 ($t=0,1$), M2/M3 chạy mô hình waypoint trên instance khác. |
| setA-14 ở hai chu kỳ của M3 | Không chồng: `P=1` và `P=2` ra hai file khác nhau. |
| setA-19 ($t=0$) tuỳ chọn | Chỉ **M3** (tuỳ chọn); M1 chỉ làm nếu M3 không làm. Đã ghi ở cả hai nơi (`HUONG_DAN_M2_M3_FINAL.md` mục 10 và `DE_XUAT_CAI_TIEN_TOI_UU.md` mục 3.1). |

### 2.2. Xung đột về file (cùng tên file)

Đã tính tập tên file mà mỗi bên sẽ sinh ra (CSV, `-loads.csv`, `-srpaths.json`, log) và đối chiếu:

- Giao của từng cặp M1/M2/M3: **rỗng**.
- Số file đã tồn tại sẵn trong repo (có thể bị ghi đè): **0** cho M2 và M3. Với M1 có 2 file (`setA-04-P2-pc-r5-5.csv`, `log-pc-P2-04-r5-5.txt`) là **file của chính lần chạy đang diễn ra** (do M1 commit giữa chừng), không phải xung đột.
- Tên file của M2/M3 (`…-wp-P<P>-cg-pc-lns…`) **khác** mọi tên file đang theo dõi, nên quy trình đẩy lên nhánh không bao giờ ở trạng thái "sửa file đã theo dõi".

### 2.3. Xung đột về git

- M2 đẩy lên `results/m2`, M3 lên `results/m3`; M1 làm việc trên `feature/tasr`. Mỗi bên một nhánh nên **không có xung đột git**.
- M1 gộp bằng `merge_member_branch.py`, chỉ **thêm** file mới, **không ghi đè** (nếu trùng tên mà khác nội dung thì bỏ qua và cảnh báo).
- **Đã thử thật** (xem 2.5): đẩy hai lần liên tiếp lên `results/m2` (lần 2 thêm vào nhánh có sẵn) đều thành công; M1 gộp nhận đủ 5 file.

### 2.4. Nhất quán giữa các tài liệu

Đã trích mọi lệnh `run_wp.jl ... 1500000 cg pc lns 900` trong `HUONG_DAN_M2_M3_FINAL.md`, `START_HERE.md`, `AGENT_BRIEFS/M2_BRIEF.md`, `AGENT_BRIEFS/M3_BRIEF.md`, `DE_XUAT_CAI_TIEN_TOI_UU.md` và so sánh: **cùng một tập lệnh** (khác duy nhất là lệnh tuỳ chọn setA-19 mà trước đây chỉ có ở file FINAL; đã bổ sung vào START_HERE và M3_BRIEF).
Các tài liệu cũ (`HUONG_DAN_CHAY_SONG_SONG.md`, `PHAN_CONG_NHOM.md`) vẫn còn phân công gốc ở dưới nhưng đầu file có khung "phân công hiện hành, không làm theo nội dung cũ".

### 2.5. Chạy thử từ đầu đến cuối (trong một bản clone sạch, nhánh `feature/tasr`)

| Bước | Kết quả |
|---|---|
| `git clone` + `checkout feature/tasr` | đúng commit mới nhất |
| `Pkg.instantiate()` | thành công |
| `run_wp.jl 1 60 1 1 1500000 cg pc lns 20` (đúng dạng lệnh của M2/M3, instance nhỏ) | mã thoát 0; sinh `setA-01-wp-P1-cg-pc-lns.csv`, `-loads.csv`, `-srpaths.json` (đúng tên đã ghi trong tài liệu) |
| Lệnh kiểm tra trong tài liệu | in `setA-01 1 Optimal 0.9293839 ok` |
| `publish_member_results.py m2 --dry-run` | liệt kê đủ 5 file (kể cả `environment-m2.txt`, `log-opt-*.txt`) |
| `publish_member_results.py m2` (đẩy thật lên remote tạm) | thành công; lần đẩy thứ hai (thêm 1 file) cũng thành công |
| Sửa nhầm file mã nguồn rồi đẩy | script **từ chối**, nêu tên file |
| `merge_member_branch.py m2` trong một clone khác | nhận đủ 5 file, không ghi đè |

Giới hạn của bài thử: chạy trên instance nhỏ (setA-01) với giới hạn thời gian ngắn và remote tạm cục bộ; **chưa đo** RAM đỉnh và thời gian của các instance thật (setA-06…18) và chưa đẩy lên GitHub thật.

### 2.6. Luồng làm việc từ `main` (cập nhật 20/10 ~11:00)

M2 và M3 **clone `main` và ở lại `main`** (không checkout nhánh khác); `publish_member_results.py` tạo `results/<ten>` từ `main` và chỉ đẩy lên đó. `merge_member_branch.py` đã được sửa để lấy điểm xuất phát là `merge-base` với `origin/main` (trước đó dùng `HEAD` của M1, nên thấy lẫn thay đổi giữa `main` và `feature/tasr`).
Đã thử: clone `main` → tạo 3 file kết quả → publish (nhánh `results/m2`, repo của thành viên ở `results/m2`) → M1 (nhánh `feature/tasr`) chạy `merge_member_branch.py m2` → nhận **đúng 3 file**, **0 cảnh báo trùng**. `main` được M1 squash merge từ `feature/tasr` mỗi khi chốt, nên luôn có đủ tài liệu và script mới nhất khi thành viên clone.

### 2.7. Xác nhận cuối (21/10 ~00:00, sau mọi thay đổi trong ngày)

Chạy lại toàn bộ kiểm tra bằng mã (kể cả các lần chạy bù của M1 `-r6-6b`, `-r10-10b`, `-r4-4v`, và phần thêm tuỳ chọn setA-19 của M3):

| Kiểm tra | Kết quả |
|---|---|
| Giao tên file giữa M1, M2, M3 | **rỗng** ở cả ba cặp |
| File sẽ bị ghi đè (đã có trong repo) | M2: không; M3: không; M1: chỉ `log-pc-P2-04-r6-6b.txt` (log của lần chạy bù bị dừng khi tắt máy, M1 tự ghi đè khi chạy lại) |
| Giao (P, instance) giữa M2 và M3; giữa M1 với M2/M3 | **rỗng** |
| Lệnh `run_wp.jl` trong `HUONG_DAN_M2_M3_FINAL.md`, `PROMPT_M2_M3.md`, `START_HERE.md`, hai file giao việc cho agent, `DE_XUAT_CAI_TIEN_TOI_UU.md` | mọi lệnh đều thuộc kế hoạch (11 lệnh trong ba file đầy đủ), **không có lệnh ngoài kế hoạch** |
| `main` so với `feature/tasr` | giống hệt |
| Nhánh từ xa | `main`, `feature/tasr`, `hung` (của Hùng, chưa merge; xem `NHAN_XET_NHANH_HUNG.md`); chưa có `results/m2`, `results/m3` |

**Kết luận:** không có chồng chéo hay xung đột giữa M1, M2, M3.

**Đính chính (phát hiện khi kiểm tra này):** trước đây các tài liệu và tin nhắn nói `main` không có dòng đồng tác giả Claude. Điều đó chỉ đúng với 11 commit squash của ngày 20/10 (không dòng nào có đồng tác giả). **Lịch sử cũ của `main` vẫn còn 17 commit (19/10, 10:33 đến 11:14, từ `dbaf8c7` đến `be28c4e`) mang dòng `Co-Authored-By` của Claude**, vì các commit đó đã nằm trong `main` trước các lần squash. Gỡ chúng cần viết lại lịch sử `main` và push ép (`--force`), việc không thể hoàn tác trên GitHub nếu không có bản sao lưu; **chưa làm**, chờ người dùng xác nhận (xem `CHAY_TIEP_SAU_KHI_BAT_MAY.md` mục 6).

---

## 3. Cách `best_known.jl` và `official_tables.jl` dùng kết quả của M2/M3

- `best_known.jl` quét mọi file `setA-XX-wp-P<P>*.csv` (không gồm `-loads.csv`) và chọn **MLU nhỏ nhất** có `check=ok`; nguồn được gắn nhãn theo hậu tố, ví dụ `wp-cg-pc-lns`.
- `official_tables.jl` dựng lại tên file từ nhãn nguồn (`wp_file`), nên hàng `*` của bảng tự trỏ tới file mới nếu nó tốt hơn. Đã kiểm tra tên: nhãn `wp-cg-pc-lns` ↔ file `setA-XX-wp-P<P>-cg-pc-lns.csv`.
- Các file `-rK-K` của M1 được `official_tables.jl` nhận bằng mẫu `-r<số>-<số>`; file của M2/M3 không khớp mẫu này nên **không lẫn** vào hàng `arc-pc`.

---

## 4. Vấn đề đã tìm thấy và đã xử lý

| # | Vấn đề | Mức độ | Xử lý |
|---|---|---|---|
| 1 | `publish_member_results.py` và `pack_member_results.py` chỉ nhận tên file có `-rA-B`; file `setA-XX-wp-…-cg-pc-lns` của M2/M3 sẽ **bị bỏ qua**, kết quả không lên được nhánh | **Cao** (mất kết quả) | Đã thêm mẫu tên; kiểm tra lại: nhận đủ |
| 2 | Máy chưa cấu hình tên git thì `publish_member_results.py` không commit được | Trung bình | Đã thêm bước đặt `git config user.name/email` vào `HUONG_DAN_M2_M3_FINAL.md` |
| 3 | Sau lần đẩy đầu tiên repo của M2/M3 nằm ở nhánh `results/<ten>`, dễ gây nhầm | Thấp | Đã giải thích trong `HUONG_DAN_M2_M3_FINAL.md` mục 5 (đã thử: đẩy lại vẫn đúng) |
| 4 | Lệnh tuỳ chọn setA-19 chỉ có ở một file | Thấp | Đã đồng bộ vào START_HERE và M3_BRIEF |

## 5. Rủi ro còn lại (không loại trừ được bằng tài liệu)

| Rủi ro | Khả năng | Cách giảm |
|---|---|---|
| M2/M3 đã đọc **bản cũ** của `START_HERE.md` (trước 09:00) và đang chạy setA-04/05 | Thấp–trung bình | Nhắn họ lấy bản mới (`git fetch`, `git checkout feature/tasr`, `git pull`) và đọc `HUONG_DAN_M2_M3_FINAL.md`; nếu vẫn lỡ chạy, bộ gộp bảng giữ bản đầu theo chỉ số lần chạy và cảnh báo trùng |
| RAM đỉnh của các instance thật cao hơn dự đoán (chưa đo) | Trung bình | Hướng dẫn nêu ngưỡng dừng (< 3 GB trống); báo nhóm để M1 chia lại |
| M1 sửa `run_wp.jl` sau này (WP2a: thêm tham số số lần chạy) làm thay đổi hành vi | Thấp | **Quy tắc cho M1:** giữ nguyên hành vi mặc định và tên file kết quả của `run_wp.jl`; M2/M3 đang chạy bản đã clone nên không bị ảnh hưởng |
| Quyền ghi GitHub của M2/M3 | Chưa biết | Hướng dẫn có đường dự phòng: `pack_member_results.py` tạo zip gửi M1 |
| `main` chậm hơn `feature/tasr` | Có | M2/M3 dùng `feature/tasr` theo hướng dẫn; M1 squash merge vào `main` khi chốt |
| Máy M2/M3 ngủ giữa chừng | Trung bình | Bước giữ máy thức; bảng sự cố hướng dẫn chạy lại chỉ lệnh chưa có file |
| Ba máy khác nhau cho thời gian khác nhau | Chắc chắn | Kết quả của M2/M3 **không** đưa vào hàng `arc-pc`. Nhưng hàng `*` lấy MLU, **thời gian, gap và nút B&B từ file tốt nhất**, nên nếu file của M2/M3 thắng thì các số đó đến từ máy của họ: M1 phải ghi rõ máy nguồn (`environment-m2/m3.txt`) trong báo cáo |
