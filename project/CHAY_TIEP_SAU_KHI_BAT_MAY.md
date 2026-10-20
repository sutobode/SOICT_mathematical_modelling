# Chạy tiếp sau khi bật lại máy (M1)

**Dừng lúc:** Thứ Ba 20/10/2026 ~23:30 (theo yêu cầu của người dùng, để tắt máy). Mọi dữ liệu đã được lưu, sao lưu zip, commit và push.

## 1. Trạng thái khi dừng

| Hàng | Số lần chạy hợp lệ | Ghi chú |
|---|---|---|
| Bảng 1 ($t=0$), setA-01…05 | 10, 10, 10, 10, 10 | đủ |
| Bảng 2 ($t=0,1$), setA-01, 02, 03 | 10, 10, 10 | đủ |
| Bảng 2, setA-04 | **9** | thiếu seed 6 |
| Bảng 2, setA-05 | **9** | thiếu seed 10 (bị watchdog dừng lúc 21:36 vì hết RAM) |
| Các hàng `*` (setA-06…20) | 1 lần mỗi hàng | mô hình thu hẹp, dấu `(1-wp)` |

**Các lần chạy bù đã bị dừng khi tắt máy** (không có dòng kết quả, sẽ mất công đã chạy):
- setA-04 ($t=0,1$) seed 6 bù: đã chạy khoảng 1 giờ 55 phút.
- setA-05 ($t=0,1$) seed 10 bù và setA-04 ($t=0$) seed 4 chạy lại: chưa bắt đầu.

## 2. Cách chạy tiếp (một lệnh)

1. **Đóng trình duyệt và ứng dụng nặng** (setA-05 cần RAM trống ≥ 12 GB; lần trước chỉ trống ~7 GB do ứng dụng khác).
2. Cắm sạc, mở terminal tại thư mục dự án và chạy:
   ```bash
   bash orange/scripts/resume_m1.sh
   ```
   Script bật các tiến trình hỗ trợ (giữ máy thức, canh RAM, chống chạy quá giờ), rồi chạy **tuần tự** ba việc: (1) setA-04 $t=0,1$ seed 6; (2) setA-05 $t=0,1$ seed 10; (3) setA-04 $t=0$ seed 4 chạy lại. Việc nào đã có kết quả hợp lệ thì bỏ qua. Nhật ký: `orange/results/resume_m1.log`.
3. Thời gian dự kiến: mỗi việc 1–2 giờ (việc 3 khoảng 30 phút); tổng 3–5 giờ.

## 3. Khi script in "XONG-RESUME"

```bash
julia orange/scripts/best_known.jl
julia orange/scripts/official_tables.jl
python -I orange/scripts/verify_srpaths.py
python -I orange/scripts/make_manifest.py
git add -A && git commit -m "data: makeup runs done" && git push origin feature/tasr
```
Rồi nhắn Claude để cập nhật báo cáo, gộp kết quả của M2/M3 (nếu có) và đồng bộ `main`.

## 4. Nếu không đủ thời gian

Mốc gộp cuối của nhóm: ~12:00 Thứ Tư 21/10. Nếu chỉ chạy được một phần, **ưu tiên theo thứ tự**: (1) setA-04 seed 6 và (2) setA-05 seed 10 (để đủ 10 lần), rồi (3) chạy lại seed 4. Hàng nào còn 9 lần thì giữ nguyên số lần thực có trong bảng (cột `Runs`); không bịa số liệu.

## 5. Điểm cần nhớ

- Các bước trên chỉ chạy được khi **máy bật liên tục**; đừng gập nắp, đừng cho ngủ.
- Đừng chạy hai tiến trình setA-04/05 $t=0,1$ cùng lúc.
- Nhánh `hung` của Hùng **chưa merge**; xem `project/NHAN_XET_NHANH_HUNG.md`.
- M2 và M3 chưa đẩy kết quả lên `results/m2`, `results/m3` (lúc dừng).
