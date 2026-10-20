# Đề xuất cải tiến tối ưu — gom lại, kèm phần M2 và M3 chạy được

**Thời điểm:** Thứ Ba 20/10/2026. **Nguyên tắc:** chỉ làm sau (hoặc song song nhưng không cản trở) các yêu cầu tối thiểu của thầy (xem `project/PHAN_TICH_YEU_CAU_VA_PHAN_VIEC.md`).
**Thay thế:** gom Phase 2 của `project/KE_HOACH_CAC_GIAI_DOAN.md` và các đề xuất rải rác ở `project/KE_HOACH_THUC_HIEN.md`, cập nhật theo kết quả thực nghiệm hôm nay.

---

## 1. Hiện trạng: chỗ nào còn "dư địa" thật sự

Mọi kết luận dưới đây rút từ `orange/results/best_known.csv` và hai bảng chính thức, không phải phỏng đoán.

### 1.1. Một phát hiện cho phép chứng minh tối ưu ngay (không tốn thời gian chạy)

Mục tiêu của bài $t=0,1$ là $\max_t$ tải, nên **$\text{opt}(t=0,1)\ \ge\ \text{opt}(t=0)$**, cả với bài toán thu hẹp (≤ 1 waypoint). Nếu hàng `*` của Bảng 2 **bằng đúng** giá trị tối ưu của Bảng 1 thì Bảng 2 đã tối ưu cho bài toán thu hẹp:

| Instance | MLU $t=0$ (Bảng 1) | MLU $t=0,1$ (Bảng 2) | Kết luận |
|---|---|---|---|
| setA-07 | 0,90799 (Optimal\*) | 0,90799 | **Tối ưu** (bài toán thu hẹp) |
| setA-08 | 0,3189 (Optimal\*) | 0,3189 | **Tối ưu** |
| setA-17 | 0,42419 (Optimal\*) | 0,42419 | **Tối ưu** |
| setA-20 | 0,99131 (Optimal\*) | 0,99131 | **Tối ưu** |

Bảng 2 đang ghi **"Not Optimal\*"** cho cả bốn hàng. Đó là nhãn sai theo hướng bi quan. Các hàng setA-07, 08, 17, 20 **không cần LNS hay chạy lâu hơn**: không thể cải thiện thêm trong bài toán thu hẹp.

### 1.2. Các hàng còn dư địa chưa biết

| Hàng ($t=0,1$) | MLU hiện tại | MLU $t=0$ (cận dưới hợp lệ) | Chênh | Đã dùng LNS chưa |
|---|---|---|---|---|
| setA-06 | 0,14085 | 0,09859 | +43 % | chưa |
| setA-09 | 0,84965 | 0,50538 | +68 % | chưa |
| setA-11 | 0,78579 | 0,61354 | +28 % | chưa |
| setA-12 | 0,87987 | 0,64008 | +37 % | chưa |
| setA-14 | 0,53315 | 0,43421 | +23 % | chưa |
| setA-15 | 0,8987 | 0,82521 | +9 % | chưa |
| setA-18 | 1,0 | 0,63337 | +58 % | chưa |
| setA-16 | 0,51639 | 0,12295 | +320 % | rồi (pipeline nhanh) |
| setA-10 | 0,1087 | 0,06957 | +56 % | rồi |
| setA-13 | 0,07692 | 0,03889 | +98 % | rồi |
| setA-19 | 0,10258 | 0,06745 | +52 % | rồi (pipeline nhanh) |

Chênh lệch **không** có nghĩa là còn cải thiện được: sau khi một cung bị tắt ở $t=1$, MLU có thể bị chặn bởi chính bước $t=1$ (đặc biệt khi ngân sách $\beta$ nhỏ). Nhưng 7 hàng đầu **chưa từng được LNS**, và LNS đã cho mức giảm rất lớn ở các hàng khác (setA-13: 0,9017 → 0,0769; setA-10: 1,0 → 0,1087; setA-16: 0,9426 → 0,5164). Đây là chỗ **thử rẻ nhất, có khả năng có lợi** → giao cho M2, M3.

### 1.3. Dư địa ở Bảng 1 ($t=0$)

| Hàng | MLU | Gap | Ghi chú |
|---|---|---|---|
| setA-04 (`arc-pc`) | 0,50105 | 0,19 | Mô hình waypoint đã có **0,45912**; hàng theo mô hình của thầy kém 8,4 % |
| setA-14 | 0,43421 | 0,024 | `wp-cg`, 1 nút B&B, chưa LNS |
| setA-19 | 0,06745 | 0,027 | 1800 s, 632 nút, chưa LNS |
| setA-10 | 0,06957 | 0,018 | đã LNS |
| setA-13 | 0,03889 | 0,001 | đã LNS, gần tối ưu |

---

## 2. Danh sách đề xuất, xếp theo giá trị / chi phí

| Mã | Đề xuất | Tác dụng | Chi phí | Ai làm | Cần sửa code? |
|---|---|---|---|---|---|
| **O1** | Đổi nhãn và gap hàng `*` bằng cận dưới từ $t=0$ (mục 1.1): "Optimal (restricted)" cho setA-07, 08, 17, 20 | Sửa nhãn sai; thêm gap có căn cứ cho các hàng khác | thấp (script) | **M1** | có (nhỏ) |
| **O2** | **LNS cho các hàng Bảng 2 chưa từng LNS**: setA-06, 09, 11, 12, 14, 15, 18 | Có thể hạ MLU; rẻ; dùng script có sẵn | 1–2 giờ máy/hàng | **M2 và M3** (mục 3) | không |
| **O3** | **LNS dài hơn cho Bảng 1**: setA-14, setA-10, setA-13 (và setA-19 nếu RAM cho phép) | Thu hẹp gap 1,8 %–2,7 % | ~30 phút/hàng | **M2 và M3** (mục 3) | không |
| **O4** | Cận dưới từ bài toán **chỉ $t=1$** (bước $t=1$ một mình, không ngân sách): chặn dưới cho Bảng 2, cho biết hàng nào "đã chạm trần" | Trả lời "còn cải thiện được không" cho 06, 09, 11, 12, 14, 15, 18 | trung bình (code mới) | **M1** viết, **M2/M3** chạy | có |
| **O5** | **Khởi tạo bằng nghiệm waypoint** cho mô hình theo cung ở setA-04 $t=0$ (warm start): hàng `arc-pc` của thầy sẽ không kém hơn 0,45912 | Hàng của mô hình thầy gần với cận tốt nhất; gap thực | trung bình (code) | **M1** | có |
| **O6** | Kiểm tra mô hình hai waypoint trên thêm vài instance (mở rộng lập luận "một waypoint đủ") | Tăng độ tin cậy của báo cáo | trung bình | M1 (chưa sẵn sàng) | có |
| **O7** | Sửa heuristic khi nhiều cung cùng tải lớn nhất; tinh chỉnh từ điển (`lex_refine`) cho nghiệm cuối | Sát mục tiêu (5) của đề | cao | M1 | có |

**Ưu tiên:** O1 → O2 → O3 (chạy được ngay, không cần code mới) → O4 → O5 → O6, O7.

**O2 và O3 là phần M2, M3 chạy được ngay hôm nay**, vì chỉ dùng script `run_wp.jl` đã có.

---

## 3. Phần giao cho M2 và M3 (O2 + O3)

### 3.1. Chia việc (không ai chạm cùng một instance)

| Người | Bảng 2 ($t=0,1$, 3600 s + LNS 900 s) | Bảng 1 ($t=0$, 1800 s + LNS 900 s) |
|---|---|---|
| **M2** | setA-06, setA-09, setA-11, setA-12 | setA-10, setA-13 |
| **M3** | setA-14, setA-15, setA-18 | setA-14 |
| **M1** (máy riêng, sau khi chạy nốt Bảng 2) | setA-16, setA-19 (nặng RAM) | setA-19 |

Mỗi hàng chạy **một lần** (bài toán gần như tất định; mục tiêu là hạ MLU, không phải lấy trung bình).

### 3.2. Lệnh chạy

**Nguồn chính để làm theo là `START_HERE.md`** (đã cập nhật cho khớp file này: mục 1 chia việc, mục 10 các lệnh). Các lệnh dưới đây trùng với `START_HERE.md` mục 10; nếu có chỗ khác nhau, `START_HERE.md` là bản đúng.

Cú pháp: `julia --project=orange orange/scripts/run_wp.jl <P> <giới_hạn_giây> <instance> <instance> 1500000 cg pc lns 900`

**M2:**
```bash
julia --project=orange orange/scripts/run_wp.jl 2 3600 6  6  1500000 cg pc lns 900 > orange/results/log-opt-P2-06.txt 2>&1
julia --project=orange orange/scripts/run_wp.jl 2 3600 9  9  1500000 cg pc lns 900 > orange/results/log-opt-P2-09.txt 2>&1
julia --project=orange orange/scripts/run_wp.jl 2 3600 11 11 1500000 cg pc lns 900 > orange/results/log-opt-P2-11.txt 2>&1
julia --project=orange orange/scripts/run_wp.jl 2 3600 12 12 1500000 cg pc lns 900 > orange/results/log-opt-P2-12.txt 2>&1
julia --project=orange orange/scripts/run_wp.jl 1 1800 10 10 1500000 cg pc lns 900 > orange/results/log-opt-P1-10.txt 2>&1
julia --project=orange orange/scripts/run_wp.jl 1 1800 13 13 1500000 cg pc lns 900 > orange/results/log-opt-P1-13.txt 2>&1
```

**M3:**
```bash
julia --project=orange orange/scripts/run_wp.jl 2 3600 14 14 1500000 cg pc lns 900 > orange/results/log-opt-P2-14.txt 2>&1
julia --project=orange orange/scripts/run_wp.jl 2 3600 15 15 1500000 cg pc lns 900 > orange/results/log-opt-P2-15.txt 2>&1
julia --project=orange orange/scripts/run_wp.jl 2 3600 18 18 1500000 cg pc lns 900 > orange/results/log-opt-P2-18.txt 2>&1
julia --project=orange orange/scripts/run_wp.jl 1 1800 14 14 1500000 cg pc lns 900 > orange/results/log-opt-P1-14.txt 2>&1
```

**Quy tắc:**
- Chạy **tuần tự**, mỗi lúc **một** tiến trình Julia.
- Không chạy lại một lệnh đã chạy xong (nó ghi đè file).
- Lệnh tạo file `setA-XX-wp-P{1|2}-cg-pc-lns.csv` (cùng `-srpaths.json`, `-loads.csv`). Tên file **không** trùng với các file hiện có, nên không ghi đè kết quả của M1.
- RAM: chưa đo đỉnh RAM của các instance này. Nếu RAM trống xuống dưới ~3 GB, dừng lại và báo; không chạy hai tiến trình cùng lúc.
- Xong từng lệnh: kiểm tra có file `.csv` và dòng cuối có `check=ok`:
  ```bash
  python -c "import csv,sys; [print(r['instance'],r['P'],r['status'],r['mlu'],r['check']) for r in csv.DictReader(open(sys.argv[1]))]" orange/results/setA-09-wp-P2-cg-pc-lns.csv
  ```

### 3.3. Cách đánh giá một kết quả

- **Có ích** nếu `check` bắt đầu bằng `ok` **và** MLU nhỏ hơn giá trị hiện tại trong `best_known.csv` (bảng ở mục 1.2/1.3).
- Nếu bằng hoặc kém hơn: vẫn **giữ file** (bằng chứng đã thử, và `best_known.jl` tự chọn giá trị tốt nhất); ghi nhận xét vào log của bạn.
- Đừng tự sửa bảng hay `best_known.csv`: M1 sẽ gộp và tạo lại bảng.

### 3.4. Đẩy kết quả

Theo mục 12 của `START_HERE.md`:
```bash
python orange/scripts/publish_member_results.py m2 --dry-run     # xem trước (đổi m2 thành m3 nếu là M3)
python orange/scripts/publish_member_results.py m2
```
Các file `log-opt-*.txt` và `setA-*-wp-*-cg-pc-lns*` cùng `environment-<tên>.txt` được đẩy lên nhánh `results/<tên>`. **Không** commit lên nhánh khác.

### 3.5. Prompt cho coding agent

> Tôi là M2 (hoặc M3). Hãy đọc `START_HERE.md` và làm đúng phần việc của vai trò của tôi (mục 1 và 10); `project/DE_XUAT_CAI_TIEN_TOI_UU.md` giải thích lý do. Không sửa file đã theo dõi, chạy tuần tự từng lệnh, không chạy lại lệnh đã xong, dừng và báo nếu RAM trống < 3 GB hoặc lệnh lỗi. Xong thì chạy `publish_member_results.py` như mục 3.4.

---

## 4. Việc M1 làm (code), để M2/M3 không phải chờ

| Mã | Việc | Điều kiện hoàn thành |
|---|---|---|
| O1 | Sửa `official_tables.jl` / `best_known.jl`: gắn cận dưới từ $t=0$ vào hàng Bảng 2; đổi nhãn | Bảng 2 ghi "Optimal (restricted)" cho setA-07, 08, 17, 20 và có gap cho các hàng khác |
| O4 | Thêm chế độ "chỉ $t=1$" (đồ thị $G_1$, $\delta(\cdot,1)$, không ngân sách) vào `run_wp.jl` | Cho biết hàng nào của mục 1.2 đã chạm trần |
| O5 | Warm start nghiệm waypoint tốt nhất vào mô hình theo cung ở setA-04 $t=0$ | Hàng `arc-pc` setA-04 ≤ 0,45912, không làm hỏng test |

Chỉ làm sau khi hoàn tất các lần chạy bắt buộc (WP1 trong file phân việc); không chiếm RAM của chúng.

---

## 5. Kỳ vọng thực tế (nói thẳng)

1. **Không đảm bảo hạ MLU.** LNS đã mạnh ở các hàng nhiều demand (setA-10, 13, 16, 19), nhưng ở các hàng nhỏ như setA-09, 11, 12, 15, 18, MLU có thể đã bị chặn bởi bước $t=1$; khi đó chạy thêm chỉ mất thời gian.
2. **Giá trị chắc chắn nhất là O1**: sửa nhãn, không cần máy, làm báo cáo trung thực hơn.
3. **Các kết quả O2/O3 chỉ cải thiện cột "Tốt nhất biết được"** và các hàng `*`; không đổi hàng `arc-pc` (mô hình của thầy) — hàng đó chỉ đổi nhờ O5.
4. Nếu M2 hoặc M3 hết thời gian, **bỏ O3 trước**, giữ O2 theo thứ tự setA-18, 09, 06, 12, 11, 14, 15 (hàng có chênh lớn trước).
