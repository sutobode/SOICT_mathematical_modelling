# Checklist kiểm tra đợt chạy thí nghiệm chính thức (T-ASR) — kế hoạch có hạn chót (v2)

Server: `10.0.12.30`, user `darkweb` (mật khẩu: xem biến `MY_SERVER_INFOR` trên máy cũ, không ghi ở đây).
Server dùng giờ **UTC**; giờ Việt Nam = UTC + 7.

## Thông tin đợt chạy

| Mục | Giá trị |
|---|---|
| Thư mục gốc | `/home/darkweb/network-model-test` |
| Repo | `SOICT_mathematical_modelling/` — nhánh `hung`, commit `0da1a520dc086e2a7c3f2f74a6212205376680be` |
| Julia | `julia-1.13.1/` (gói: `julia-depot/`) |
| Script điều phối **đang dùng** | `pipeline2.sh` (chạy lại = resume). `pipeline.sh` là bản cũ, **không chạy lại**. |
| Xem trạng thái | `status.sh` (chỉ đọc) |
| Log | `logs/` (`pipeline.log` chung; mỗi batch v2 có `logs/v2_<tên>.log`) |
| Test | Qua hết lúc 2026-10-20 15:52 UTC |
| Hạn chót của bạn | **8h sáng 23/10 giờ VN = 01:00 UTC 23/10** |
| Hạn chót thí nghiệm trong script | **00:00 UTC 23/10** (07:00 VN). Đến giờ đó job đang chạy bị dừng, rồi script tự tạo bảng. |

### Lịch sử
- 20/10 15:52–16:17 UTC: kế hoạch cũ (batch 1) chạy xong P=1 setA-01..03 (30 run hợp lệ). Lúc 16:17 UTC tôi dừng nó, khi đang ở setA-04 P=1 run 1; run dở này sẽ chạy lại từ đầu.
- 20/10 16:17 UTC: chuyển sang kế hoạch v2 theo thứ tự ưu tiên.

### Thứ tự batch trong `pipeline2.sh` và dự kiến

| Tên batch (log/marker) | Lệnh | Dự kiến xong (UTC) | Giờ VN |
|---|---|---|---|
| `p1_s01-03` | `run_experiments.jl 1 1800 1 3 pc 1 10` | **Đã xong** (30 run `skipped`) | |
| `p2_s01-03` | `run_experiments.jl 2 3600 1 3 pc 1 10` | khoảng 21/10 04:00–07:00 (tệ nhất khoảng 13:00) | 11h–14h ngày 21/10 |
| `p1_s04-05` | `run_experiments.jl 1 1800 4 5 pc 1 10` | khoảng 21/10 10:00–13:00 | khoảng 17h–20h ngày 21/10 |
| `p2_s04-05` | `run_experiments.jl 2 3600 4 5 pc 1 10` | khoảng 22/10 09:00–12:00 | khoảng 16h–19h ngày 22/10 |
| `wp_p1_s10` (tùy chọn) | `run_official_wp.jl 1 1800 10 10 1 10` | khoảng 22/10 14:00–17:00 | |
| `wp_p2_s07` (tùy chọn) | `run_official_wp.jl 2 3600 7 7 1 10` | ngay sau đó (vài phút) | |
| bảng | `official_tables.jl orange/results report` | ngay sau batch cuối, hoặc 00:00 UTC 23/10 | |

(Tất cả lệnh `run_experiments.jl` có tiền tố `ORANGE_MAX_VARS=16000000` cho P=1 và `10000000` cho P=2.)

**Luật hạn chót:**
- Một batch chỉ được bắt đầu nếu thời gian còn lại ≥ ước tính tệ nhất của nó: 21 h, 11 h, 24 h, 6 h và 2 h theo thứ tự trên.
- Hai batch WP tùy chọn chỉ chạy nếu cả 4 batch ưu tiên đều xong.
- Pipeline tự dừng (STOP) nếu RAM trống dưới **40 GB** (đổi từ 60 GB lúc 16:22 UTC 20/10). Ngưỡng chỉ được kiểm tra trước mỗi batch.

**Sáng 21/10 (8h VN = 01:00 UTC):** đang chạy `p2_s01-03`, nhiều khả năng ở setA-02 P=2 (khoảng 50 phút mỗi run).

## Bước 0 — Đăng nhập

```bash
ssh darkweb@10.0.12.30
cd /home/darkweb/network-model-test
```

## Bước 1 — Tiến trình còn chạy không?

```bash
bash status.sh
pgrep -af 'pipeline2\.sh|scripts/run_'
```

- [ ] Có dòng `bash pipeline2.sh` (hoặc `bash /home/darkweb/network-model-test/pipeline2.sh`). Nếu batch đầu `p2_s01-03` **chưa xong**, thay vào đó sẽ thấy dòng `bash -c while kill -0 1125961 ...; exec bash .../pipeline2.sh`. Đây là bình thường: tiến trình này chờ batch hiện tại xong rồi khởi chạy lại pipeline với ngưỡng RAM 40 GB.
- [ ] Có dòng `julia ... run_experiments.jl ...` hoặc `run_official_wp.jl ...` (kèm một dòng `timeout ...`, là bình thường)
- [ ] Chỉ có **một** tiến trình Julia thí nghiệm

Nếu không thấy tiến trình nào **và** `logs/pipeline.log` chưa có `V2 PIPELINE FINISHED`, thì đọc tiếp Bước 6.

## Bước 2 — Dòng thời gian batch, có STOP không?

```bash
grep -E 'V2|SWITCH|STOP|TABLES' logs/pipeline.log
ls logs/*.done
```

- [ ] Không có dòng `STOP`
- [ ] Mọi dòng `V2 ... END` đều có `rc=0`. `rc=124` chỉ hợp lệ khi đã tới hạn chót.
- [ ] Không có `attempt=2` hoặc `attempt=3`. Nếu có thì batch đó đã từng crash và đã tự chạy lại để resume. Xem `logs/v2_<tên>.log` ngay trước dòng `===== ... attempt 2`.
- [ ] Không có `NOT STARTED` ngoài dự kiến

## Bước 3 — Từng run có hợp lệ không?

Mỗi run in ra một trong ba trạng thái: `ran` (hợp lệ), `skipped` (đã có kết quả hợp lệ từ trước) hoặc **`incomplete`** (không hợp lệ).

```bash
# số run theo trạng thái, theo từng instance (đổi tên log theo batch)
awk '/^== /{inst=$2} /^   (ran|skipped|incomplete)/{c[inst" "$1]++} END{for(k in c) print k, c[k]}' logs/v2_p2_s01-03.log | sort

# lỗi / RAM guard trên mọi log v2
grep -n -E 'incomplete|SKIPPED_LOW_MEMORY|ERROR|Error|OutOfMemory|Killed' logs/v2_*.log | head -30
```

- [ ] Mỗi instance đã chạy qua đều có 10 run `ran` hoặc `skipped`
- [ ] Không có `incomplete`
- [ ] Không có `SKIPPED_LOW_MEMORY`. Nếu có, ghi lại instance, P và RAM trống. **Không** được vượt guard.
- [ ] Không có `ERROR` hoặc `OutOfMemory`

Lưu ý: run chạm giới hạn thời gian (1800 s với P=1, 3600 s với P=2) mà vẫn có nghiệm và cận là **bình thường**.

## Bước 4 — Tài nguyên server

```bash
free -h
df -h /home/darkweb
ps -eo pid,user,%cpu,%mem,etime,args --sort=-%mem | head -8
```

- [ ] `available` vẫn trên 40 GB
- [ ] Swap không tăng mạnh (lúc bắt đầu dùng 3.7 GB / 8 GB)
- [ ] Ổ đĩa còn trống (lúc bắt đầu còn 279 GB)
- [ ] Không có job lớn mới của người khác tranh RAM. **Không** đụng vào tiến trình của người khác (ví dụ `/home/darkweb/duc/...malware_pipeline_server`).

## Bước 5 — File kết quả

```bash
cd SOICT_mathematical_modelling
ls orange/results/ | grep -E 'P1-official-pc-r[0-9]+\.csv$' | wc -l   # số run P=1 đã ghi
ls orange/results/ | grep -E 'P2-official-pc-r[0-9]+\.csv$' | wc -l   # số run P=2 đã ghi
git log -1 --format=%H                                                # phải vẫn là 0da1a52...
git status --short | grep -v '^??' | head                              # phải RỖNG (không file tracked nào bị sửa)
```

## Bước 6 — Nếu tiến trình đã chết (server reboot, bị kill...)

1. **Không** xóa file nào trong `orange/results/` hay `logs/`.
2. Ghi lại: `tail -40 logs/pipeline.log; tail -40 logs/v2_<batch đang chạy>.log`.
3. Kiểm tra RAM (Bước 4), rồi chạy lại để resume. Batch đã xong (có `logs/v2_*.done`) sẽ được bỏ qua.

```bash
cd /home/darkweb/network-model-test
setsid nohup bash pipeline2.sh > logs/pipeline2.out 2>&1 < /dev/null &
```

**Không** chạy lại `pipeline.sh` (bản cũ).

## KHÔNG được làm

- Không dùng `ORANGE_FORCE_RESTART=1`.
- Không sửa code, test, tài liệu, CSV kết quả, `best_known.csv`, bảng hay artifact.
- Không tự đổi khoảng run hay instance để resume. Chỉ chạy lại `pipeline2.sh`.
- Không chạy thêm job Julia thí nghiệm song song.
- Không chạy P=1 setA-11/12 hay P=2 setA-06/08/09 trong đợt này.
- Không chạy thí nghiệm lexicographic hay so sánh bản cũ.
- Không thao tác ngoài `/home/darkweb/network-model-test`.

## Khi xong (muộn nhất khoảng 00:10 UTC 23/10 = 07:10 VN)

`logs/pipeline.log` sẽ có `TABLES end rc=0` và `V2 PIPELINE FINISHED`.

```bash
cd SOICT_mathematical_modelling
cat orange/results/table_official_P1.md orange/results/table_official_P2.md
grep INCOMPLETE orange/results/table_official_P*.csv        # liệt kê các dòng chưa đủ
grep -E -v 'verified' orange/results/best_known.csv | head  # các dòng chưa VERIFIED
ls report/table_official_P*.tex
```

Kỳ vọng:
- [ ] setA-01..03, P=1 và P=2: đủ 10 run, `verified` (**mức tối thiểu**)
- [ ] setA-04..05, P=1 và P=2: đủ 10 run, `verified` (**mức mong muốn**)
- [ ] (tùy chọn) WP P=1 setA-10 và WP P=2 setA-07: được ghi là model **restricted**, chỉ là cận trên khả thi, không phải nghiệm tối ưu của bài toán gốc
- [ ] Các instance ngoài phạm vi (setA-06..20 trừ các WP trên) sẽ là `INCOMPLETE` trong bảng. Điều này **đúng với kế hoạch**, không phải lỗi. Không vá tay.

## Ghi chú

- Bước kiểm tra artifact gọi lệnh `python`; server chỉ có `python3`, nên đã tạo symlink `network-model-test/bin/python → /usr/bin/python3`. Nếu tự chạy `official_tables.jl` bằng tay, trước đó phải chạy:
  `export PATH=/home/darkweb/network-model-test/bin:/home/darkweb/network-model-test/julia-1.13.1/bin:$PATH JULIA_DEPOT_PATH=/home/darkweb/network-model-test/julia-depot`
  Nếu không, artifact sẽ bị báo `verification_failed`.
- Kết quả chỉ có trên server, chưa commit hay đưa về máy nào.
