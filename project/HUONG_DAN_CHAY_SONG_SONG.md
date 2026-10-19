# Kế hoạch và phân công chạy thực nghiệm song song cho 3 máy

> **CẬP NHẬT 00:40 Thứ Ba 20/10:** M2 và M3 chưa chạy, nên máy M1 chạy **setA-05 $t=0,1$ seed 1–5** (làm pilot) trong đêm, sau khi setA-04 $t=0,1$ xong lần 4. Phân công mới cho setA-05: **M1 seed 1–5, M2 seed 6–8, M3 seed 9–10**; setA-04 $t=0,1$: M1 seed 1–4, M2 seed 5–7, M3 seed 8–10. Bảng và lệnh chính xác nằm trong `START_HERE.md` (nguồn đúng nhất); các bảng bên dưới có thể lệch.

> Lập lúc 00:10 Thứ Ba 20/10/2026. **Mốc cứng: xong hết trước T4 (Thứ Tư 21/10).** Phạm vi: **chỉ code và chạy thực nghiệm** (chưa viết báo cáo).
> Máy của người điều phối (**M1**) **tiếp tục chạy Phase 1 như hiện tại**, không đổi. Hai thành viên còn lại (**M2, M3**) nhận các khoảng chạy **rời nhau** bên dưới.

## 1. Nguyên tắc để không xung đột và không trùng việc

1. **Mỗi lần chạy có một số thứ tự (seed) 1 đến 10.** Mỗi máy chỉ chạy **đúng khoảng seed được giao** cho **đúng dòng** được giao. Các khoảng ở bảng 2 **không giao nhau**.
2. **File kết quả có tên theo khoảng** (`-r5-7`, `-r8-10`, ...): hai máy không bao giờ ghi vào cùng một file. Bảng chính thức tự gộp mọi file và bỏ trùng số thứ tự; nếu có trùng, `official_tables.jl` in cảnh báo.
3. **Không sửa mã nguồn, không sửa file dùng chung, không `git push`.** Thành viên chỉ chạy lệnh trong tài liệu này và gửi lại gói kết quả. Như vậy không có xung đột git.
4. **Mỗi máy chỉ chạy một tiến trình Julia nặng tại một thời điểm** (RAM). Đừng chạy hai lệnh cùng lúc.
5. **Không chạy lại một khoảng đã chạy:** lệnh ghi đè file của khoảng đó. Nếu một khoảng bị gián đoạn giữa chừng, chạy phần còn thiếu bằng **khoảng con với hậu tố mới** (mục 6).
6. **Cấm chạy việc nặng khác** trong lúc chạy (thời gian là số liệu nộp).

## 2. Phân công

Còn thiếu (số liệu lúc 23:58): Bảng 1 / setA-04: lần 8–10; Bảng 2 / setA-02: lần 6–10; setA-03: lần 6–10; setA-04: lần 3–10; setA-05: lần 1–10 (chưa chạy).

| Máy | Thứ tự | Dòng, khoảng seed | Số lần | Thời gian ước lượng | RAM |
|---|---|---|---|---|---|
| **M1** (đang chạy, giữ nguyên) | — | Bảng 1 / setA-04 lần 8–10; Bảng 2 / setA-02 lần 6–10; setA-03 lần 6–10; **setA-04 lần 3–4** (dừng tiến trình sau lần 4) | 3 + 5 + 5 + 2 | khoảng 4 đến 6 giờ, xong ~04:00–06:00 | đang dùng ~10 GB |
| **M2** | 1 | **Pilot** Bảng 2 / setA-05, **lần 1** (kiểm tra có chạy được không) | 1 | ~65 phút | ≥ 14 GB trống |
| | 2 | Bảng 2 / setA-04, **lần 5–7** | 3 | ~3,2 giờ | ~8 GB đỉnh |
| | 3 | Bảng 2 / setA-05, **lần 2–5** (chỉ nếu pilot thành công) | 4 | ~4,4 giờ | ≥ 14 GB trống |
| **M3** | 1 | Bảng 2 / setA-04, **lần 8–10** | 3 | ~3,2 giờ | ~8 GB đỉnh |
| | 2 | Bảng 2 / setA-05, **lần 6–10** (chỉ nếu pilot của M2 thành công) | 5 | ~5,4 giờ | ≥ 14 GB trống |

Tổng M2 và M3 khoảng **8,5 giờ mỗi người** nếu bắt đầu lúc ~00:30, tức xong khoảng **09:00 sáng Thứ Ba**. Sau đó còn Phase 1c (đo lại thời gian sạch) và Phase 3 (hoàn tất), vẫn trước T4.

**Quy tắc quyết định pilot:** M2 báo ngay kết quả của pilot (lần 1 của setA-05, sau ~65 phút):
- Status là `Optimal`, `Not Optimal` kèm một MLU hợp lệ (cột `check` = `ok`): **tiếp tục** (M2 mục 2–3, M3 mục 2).
- Status là `SKIPPED_LOW_MEMORY`, `ERROR`, hoặc máy sập: **dừng setA-05**; dòng này giữ nghiệm waypoint (`*`). M2 và M3 chỉ làm setA-04.

**Nếu máy của M2 hoặc M3 chỉ có 16 GB RAM:** không chạy setA-05 (cần ≥ 14 GB trống, thực tế phải có ≥ 24 GB RAM). Báo cho M1 để chia lại: setA-04 lần 5–7 và 8–10 vẫn chạy được (đỉnh ~8 GB nếu đóng hết ứng dụng).

## 3. Chuẩn bị (mỗi thành viên, ~30 phút, làm một lần)

### 3.1 Yêu cầu máy
- RAM: **≥ 16 GB** (setA-04) hoặc **≥ 24 GB** (setA-05); đóng trình duyệt và ứng dụng nặng; cắm sạc; Windows, Linux hoặc macOS.
- Julia **1.13.1** (cài bằng `juliaup`: `juliaup add 1.13.1` rồi `juliaup default 1.13.1`), Python 3.

### 3.2 Lấy mã nguồn
Nhận file `member_kit_<commit>.zip` từ M1 (chứa toàn bộ mã nguồn, dữ liệu SetA, khóa phiên bản thư viện). Giải nén ra một thư mục, ví dụ `C:\soict`. Mọi lệnh bên dưới chạy **từ thư mục gốc đó**.

### 3.3 Cài thư viện và kiểm tra nhanh
```bash
julia --project=orange -e "using Pkg; Pkg.instantiate()"
julia --project=orange orange/test/runtests.jl            # ~2–5 phút, mọi test phải đạt (không có dòng Fail/Error)
```

### 3.4 Ghi lại môi trường máy (bắt buộc, để thầy truy vết)
Thay `<ten>` bằng tên của bạn (ví dụ `m2`, `m3`):
```bash
julia --project=orange -e "using InteractiveUtils; versioninfo(); using Pkg; Pkg.status()" > orange/results/environment-<ten>.txt
```
Windows (PowerShell), ghi thêm CPU/RAM:
```powershell
Get-CimInstance Win32_Processor | Select -Expand Name | Add-Content orange\results\environment-<ten>.txt
"RAM GB: " + [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1) | Add-Content orange\results\environment-<ten>.txt
(Get-CimInstance Win32_OperatingSystem).Caption | Add-Content orange\results\environment-<ten>.txt
```

### 3.5 Giữ máy thức (Windows)
Cắm sạc, không gập nắp, và chạy ở một cửa sổ PowerShell riêng:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File orange\scripts\keep_awake.ps1
```

### 3.6 Kiểm tra trước khi chạy (khoảng 1 phút)
```bash
julia --project=orange orange/scripts/run_experiments.jl 2 60 1 1 pc 1 1 -smoke
```
Mở `orange/results/setA-01-P2-pc-smoke.csv`: phải có 1 dòng với `status = Optimal` và `check = ok`. File `-smoke` không được gộp vào bảng chính thức.

## 4. Lệnh chạy

Chạy **lần lượt**, đợi lệnh trước kết thúc mới chạy lệnh sau, mỗi lệnh một cửa sổ terminal (không đóng terminal trong lúc chạy). Cú pháp:
`run_experiments.jl <P> <giới_hạn_giây> <instance_đầu> <instance_cuối> pc <seed_đầu> <seed_cuối> <hậu_tố>`.

### M2
```bash
# 1) PILOT: setA-05, t=0,1, lần 1
julia --project=orange orange/scripts/run_experiments.jl 2 3600 5 5 pc 1 1 -r1-1 > orange/results/log-pc-P2-05-r1-1.txt 2>&1
#    -> báo ngay cho M1 nội dung: tail -n 2 orange/results/setA-05-P2-pc-r1-1.csv

# 2) setA-04, t=0,1, lần 5–7
julia --project=orange orange/scripts/run_experiments.jl 2 3600 4 4 pc 5 7 -r5-7 > orange/results/log-pc-P2-04-r5-7.txt 2>&1

# 3) setA-05, t=0,1, lần 2–5   (CHỈ nếu pilot thành công)
julia --project=orange orange/scripts/run_experiments.jl 2 3600 5 5 pc 2 5 -r2-5 > orange/results/log-pc-P2-05-r2-5.txt 2>&1
```

### M3
```bash
# 1) setA-04, t=0,1, lần 8–10
julia --project=orange orange/scripts/run_experiments.jl 2 3600 4 4 pc 8 10 -r8-10 > orange/results/log-pc-P2-04-r8-10.txt 2>&1

# 2) setA-05, t=0,1, lần 6–10   (CHỈ nếu pilot của M2 thành công; M1 sẽ báo)
julia --project=orange orange/scripts/run_experiments.jl 2 3600 5 5 pc 6 10 -r6-10 > orange/results/log-pc-P2-05-r6-10.txt 2>&1
```

**Nếu máy báo `SKIPPED_LOW_MEMORY` dù bạn chắc đủ RAM trống:** thêm tham số cuối là số GB cho phép, ví dụ `... pc 1 1 -r1-1 14` (chỉ dùng khi Task Manager cho thấy RAM trống thật ≥ 14 GB; nếu RAM cạn, hệ điều hành sẽ làm chậm hoặc đóng tiến trình).

## 5. Theo dõi khi đang chạy

- Một lần chạy của setA-04 mất ~60 phút nên **không có dòng mới trong CSV cho đến khi xong lần đó**; đây là bình thường.
- Kiểm tra tiến trình sống: Task Manager phải có `julia.exe` dùng CPU ~1 lõi (khoảng 6–7% trên máy 16 luồng) và RAM ~6–8 GB (setA-04) hoặc ~11 GB (setA-05).
- Xem tiến độ: `type orange\results\setA-04-P2-pc-r5-7.csv` (Windows) hoặc `cat ...` (mỗi dòng là một lần chạy xong). Cột chính: `run, status, mlu, solve_time, check`.
- Log solver nguyên văn của từng lần chạy: `orange/results/solverlogs/setA-04-P2-pc-r5-7-run5.log` (và các `run6`, `run7`).
- **Báo cáo trạng thái cho M1:** mỗi lần xong một khoảng hoặc khi có sự cố, gửi: tên bạn, tên lệnh, `tail -n 3` của CSV, và ghi chú nếu máy từng ngủ, tắt hoặc chạy việc khác.

## 6. Khi có sự cố

| Tình huống | Làm gì |
|---|---|
| Máy ngủ hoặc tắt giữa chừng | Xem CSV đã có bao nhiêu lần chạy xong. Chạy **phần còn lại** bằng hậu tố mới, ví dụ nếu `-r5-7` mới xong lần 5: `... pc 6 7 -r6-7`. **Không** chạy lại `-r5-7` (sẽ ghi đè). |
| `julia` báo hết bộ nhớ hoặc bị đóng | Đóng ứng dụng khác, chạy lại **phần chưa xong** bằng hậu tố mới, báo cho M1. |
| `status = SKIPPED_LOW_MEMORY` ở setA-04 | Kiểm tra RAM trống; đóng ứng dụng; nếu vẫn thiếu, báo M1 để chia lại. |
| `check` khác `ok` hoặc `ERROR` | Giữ nguyên file, gửi cho M1 kèm log; **không** tự chạy lại. |
| Thấy hai dòng cùng `run` trong các file | Báo M1 (chồng chéo); không xóa file. |

## 7. Gửi kết quả về

Sau mỗi khoảng (hoặc khi M1 yêu cầu), trên máy của mình:
```bash
python orange/scripts/pack_member_results.py <ten>
```
Lệnh tạo `member_results/<ten>_<ngày_giờ>.zip` (CSV, log solver, log chạy, môi trường, SHA-256). Gửi file zip cho M1. **Không** gửi cả thư mục dự án.

### M1 nhận và gộp (làm lần lượt từng gói)
```bash
# giải nén zip vào orange/ (nó chứa thư mục results/); không ghi đè file có sẵn của M1
python -I orange/scripts/make_manifest.py
julia orange/scripts/best_known.jl
julia orange/scripts/official_tables.jl        # cảnh báo nếu có chồng chéo số thứ tự
python -I orange/scripts/verify_srpaths.py     # kiểm tra độc lập các nghiệm mới
```
Sau khi gộp, bảng chính thức tự có số lần chạy mới ở cột `Runs`. Tên thành viên và máy được ghi trong `environment-<ten>.txt` và `MANIFEST.csv`.

## 8. Tiêu chí hoàn thành của từng máy

| Máy | Hoàn thành khi |
|---|---|
| M2 | có đủ các file `setA-05-P2-pc-r1-1.csv`, `setA-04-P2-pc-r5-7.csv` (3 dòng), `setA-05-P2-pc-r2-5.csv` (4 dòng, nếu pilot ổn), log solver tương ứng, `environment-m2.txt`, đã gửi gói zip |
| M3 | có đủ `setA-04-P2-pc-r8-10.csv` (3 dòng), `setA-05-P2-pc-r6-10.csv` (5 dòng, nếu pilot ổn), log solver, `environment-m3.txt`, đã gửi gói zip |
| M1 | các tiến trình đang chạy xong (Bảng 1 setA-04 đủ 10 lần; Bảng 2 setA-02, 03 đủ 10 lần; setA-04 có lần 1–4) và dòng setA-19 của Bảng 2 |

Khi cả ba hoàn thành: Bảng 1 và Bảng 2 có **10 lần chạy cho mọi dòng theo đề** (và setA-05 ở $t=0,1$ nếu pilot ổn).

## 9. Lịch

| Khi nào | M1 | M2 | M3 |
|---|---|---|---|
| T3 00:30–01:30 | tiếp tục Phase 1 | cài đặt + smoke test; **pilot** setA-05 lần 1 | cài đặt + smoke test; setA-04 lần 8–10 (bắt đầu) |
| T3 ~01:40 | dừng tiến trình setA-04 sau lần 4 | báo kết quả pilot | — |
| T3 01:40–05:00 | các lần chạy còn lại của M1 | setA-04 lần 5–7 | setA-04 lần 8–10 |
| T3 05:00–09:00 | Phase 1c bắt đầu khi M1 rảnh | setA-05 lần 2–5 | setA-05 lần 6–10 |
| T3 09:00 | gộp gói của M2, M3; làm mới bảng | gửi gói zip | gửi gói zip |
| T3 trưa đến tối | Phase 1c (đo thời gian sạch), kiểm chứng, manifest | rảnh | rảnh |
| T4 sáng | Phase 3: hoàn tất và bàn giao | | |

## 10. Việc code song song (không bắt buộc, chỉ khi có người rảnh và biết Julia)

Mỗi việc nằm ở **file riêng** để không xung đột; làm trên **bản sao** của thư mục, gửi lại file đã sửa cho M1 (không sửa trực tiếp trên bản dùng chung):

| Việc | File | Ghi chú |
|---|---|---|
| Sửa nhãn trạng thái dòng waypoint ở Bảng 2 ("Optimal (restricted)" / "Not certified") | `orange/scripts/official_tables.jl` | do M1 làm |
| LNS cho các dòng Bảng 2 có nghiệm yếu (setA-18, 07, 20 gần mức cơ sở) | script mới `orange/scripts/lns_weak_rows.jl` | M2 hoặc M3 sau khi xong phần chạy |
| Cận dưới chặt hơn cho $P=2$ (ngân sách trong định giá) | `orange/src/wpmodel.jl` | rủi ro cao, để sau |
| Sửa các lỗi nhỏ đã hoãn (heuristic dừng khi nhiều cung cùng tải) | `orange/src/heuristic.jl` | rủi ro thấp |

## 11. Điều cần nhớ

- Phân công này **không đổi các số liệu đã có**; nó chỉ **bổ sung các lần chạy còn thiếu** để mỗi dòng theo đề đủ 10 lần.
- Số liệu thời gian giữa các máy khác nhau do phần cứng khác nhau: mỗi máy ghi `environment-<ten>.txt`, và báo cáo sẽ nêu rõ.
- Mọi sự kiện được ghi vào `orange/results/RUN_JOURNAL.md` (M1 cập nhật).

## 12. Dùng coding agent để làm các việc trên

Mỗi thành viên có thể giao toàn bộ phần việc của mình cho một coding agent (Claude Code, Cursor, Codex, ...):

1. Giải nén `member_kit_<commit>.zip`, **mở thư mục đó** bằng agent.
2. Mở `project/AGENT_BRIEFS/M2_BRIEF.md` (hoặc `M3_BRIEF.md`), sao chép **khối PROMPT** và dán vào agent. Ngữ cảnh chung và các quy tắc bắt buộc nằm ở `project/AGENT_BRIEFS/00_NGU_CANH_CHUNG.md` (agent tự đọc).
3. Agent tự làm: kiểm tra máy (`orange/scripts/preflight.py`), cài thư viện, chạy bộ test, ghi `environment-<ten>.txt`, chạy các lệnh được giao ở chế độ nền, kiểm tra từng khoảng bằng `orange/scripts/check_range.py`, đóng gói bằng `pack_member_results.py` và viết báo cáo cuối theo mẫu.
4. Bạn (thành viên) chỉ cần: giữ máy thức và đóng ứng dụng nặng, trả lời khi agent hỏi (ví dụ xác nhận RAM trống, hoặc kết quả pilot của M2 trước khi M3 chạy setA-05), và gửi file zip kết quả cho M1.
5. Các việc **code** không bắt buộc (heuristic, chạy LNS cho dòng yếu) nằm ở `project/AGENT_BRIEFS/CODE_TASKS.md`; chỉ giao sau khi xong phần chạy.

**Các rào chắn đã đặt cho agent** (đều có trong brief): không sửa file được theo dõi, không dùng git, chỉ một tiến trình Julia nặng một lúc, không chạy lại khoảng đã có CSV, mọi lệnh dài chạy nền và chỉ kiểm tra mỗi 20–30 phút, dừng và hỏi người khi có bất thường.

**Script hỗ trợ agent:**
- `python orange/scripts/preflight.py` — kiểm tra Julia/RAM/dữ liệu, kết luận máy nhận được việc nào.
- `python orange/scripts/check_range.py <csv> <seed_đầu> <seed_cuối>` — kết luận `COMPLETE` / `INCOMPLETE` / `PROBLEM` (mã thoát 0 / 2 / 3).
- `python orange/scripts/pack_member_results.py <ten>` — đóng gói kết quả để gửi M1.
