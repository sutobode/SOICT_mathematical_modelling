# HƯỚNG DẪN CHÍNH THỨC (FINAL) cho M2 và M3

> **Đây là bản đúng nhất.** Nếu `START_HERE.md` hoặc tài liệu khác trong `project/` có chỗ khác với file này, **làm theo file này**.
> Dành cho: thành viên M2, M3 (hoặc coding agent của họ). Bạn không cần hỏi ai: làm theo từng bước.
> Cập nhật: Thứ Ba 20/10/2026. Hạn của nhóm: xong trước **Thứ Tư 21/10**.

---

## Tóm tắt một trang (checklist)

M2 và M3 làm **song song, độc lập**, trên **máy của chính mình**: không ai chờ ai, không ai chờ M1, không ghi chung file nào.

- [ ] **Bước 0 (mục 3):** clone, cài Julia 1.13.1, chạy test, ghi `environment-<ten>.txt`, bật giữ máy thức, thử nhanh (≈ 30 phút).
- [ ] **Bước 1 (mục 4):** chạy các lệnh của bạn **tuần tự, một lần mỗi lệnh** (M2: 6 lệnh; M3: 4 lệnh).
- [ ] **Sau mỗi lệnh xong (mục 5):** kiểm tra `check=ok`, rồi `publish_member_results.py <ten>`.
- [ ] **Xong hết (mục 7):** nhắn nhóm báo cáo cuối theo mẫu.
- [ ] **Xong sớm (mục 10):** phần thêm tuỳ chọn, hoặc báo nhóm rồi nghỉ.
- Mốc: **M1 gộp kết quả khoảng 20:00 tối nay (20/10) và lần cuối khoảng 12:00 sáng T4 (21/10)**; cứ có kết quả là đẩy ngay, đừng đợi xong hết (mục 9).

---

## 1. Việc của bạn trong 30 giây

Dự án: giải bài toán **T-Adaptive Segment Routing** (Orange, ROADEF 2026) bằng Julia (JuMP + HiGHS). Kết quả chính đã có. Bạn chạy **một số thử nghiệm cải tiến** để thử hạ giá trị MLU (tải lớn nhất trên các cung) của vài instance, rồi đẩy kết quả lên nhánh riêng của bạn.

- Bạn chạy **các lệnh ở mục 4**, **từng lệnh một**, mỗi lệnh **một lần**.
- Bạn **không** chạy setA-04 và setA-05 ở $t=0,1$ (M1 đang chạy hết phần đó trên máy của M1).
- Bạn **không sửa file nào** của dự án; chỉ tạo file mới trong `orange/results/`.

| | Bảng 2 ($t=0,1$, `P=2`, giới hạn 3600 s) | Bảng 1 ($t=0$, `P=1`, giới hạn 1800 s) | Tổng thời gian ước tính |
|---|---|---|---|
| **M2** | setA-**06, 09, 11, 12** | setA-**10, 13** | ~4–6 giờ |
| **M3** | setA-**18, 14, 15** | setA-**14** | ~3–5 giờ |

Hai danh sách **không giao nhau**. Không đổi instance, không đổi thứ tự. Mục đích và cách làm song song: mục 9–11. (Lý do chọn instance: `project/DE_XUAT_CAI_TIEN_TOI_UU.md`; bạn không cần đọc để làm.)

---

## 2. Điều kiện máy

- RAM tổng **≥ 16 GB**; RAM **trống** lúc chạy **≥ 8 GB** (đóng trình duyệt và ứng dụng nặng). Ổ cứng trống ≥ 2 GB.
- Cắm sạc, tắt chế độ ngủ, **không gập nắp laptop**, không chạy việc nặng khác khi đang chạy.
- Windows, Linux hoặc macOS đều được.
- Máy yếu hơn thế này: **nhắn nhóm** để M1 chia lại. Đừng tự đổi việc.

---

## 3. Chuẩn bị (làm một lần, khoảng 30 phút)

Mọi lệnh chạy từ thư mục gốc của repo (`soict`).

**Bước 1 — Lấy mã nguồn**
```bash
git clone https://github.com/sutobode/SOICT_mathematical_modelling.git soict
cd soict
git checkout feature/tasr          # KHÔNG làm việc trên nhánh main
git log -1 --oneline               # ghi lại commit này (đưa vào báo cáo cuối của bạn)
```
Nếu `git clone` báo không có quyền, nhờ chủ repo (`sutobode`) hỗ trợ, hoặc xin file zip `member_kit_*.zip` (giải nén ra thư mục `soict`).

Nếu máy của bạn **chưa cấu hình tên git** (lệnh `git config user.name` không in gì), đặt tên của **chính bạn** (không dùng tên người khác) để bước đẩy kết quả (mục 5) commit được:
```bash
git config user.name "Tên của bạn"
git config user.email "email-của-bạn@example.com"
```

**Bước 2 — Cài phần mềm**
- Julia **1.13.1** (đúng phiên bản):
  - Windows: `winget install --id Julialang.Juliaup -e`, mở lại terminal, rồi `juliaup add 1.13.1` và `juliaup default 1.13.1`.
  - Linux/macOS: `curl -fsSL https://install.julialang.org | sh`, mở lại terminal, rồi `juliaup add 1.13.1` và `juliaup default 1.13.1`.
  - Kiểm tra: `julia --version` phải in `julia version 1.13.1`.
- Python 3.9 trở lên: `python --version` (Linux/macOS có thể là `python3`).

**Bước 3 — Kiểm tra máy**
```bash
python orange/scripts/preflight.py
```
Phải thấy `[OK   ]` cho Julia, dữ liệu (60 file) và script. Bỏ qua dòng "Ket luan" về setA-04/setA-05 (của phân công cũ).

**Bước 4 — Cài thư viện và chạy test** (5–15 phút, lần đầu lâu vì biên dịch)
```bash
julia --project=orange -e "using Pkg; Pkg.instantiate()"
julia --project=orange orange/test/runtests.jl
```
Mong đợi: các dòng `Test Summary: ... Pass ...`, **không có** `Fail` hay `Error`. Nếu có: **dừng** và báo nhóm kèm 30 dòng cuối output.

**Bước 5 — Ghi môi trường máy** (bắt buộc, để thầy truy vết). Thay `<ten>` bằng `m2` hoặc `m3`:
```bash
julia --project=orange -e "using InteractiveUtils; versioninfo(); using Pkg; Pkg.status()" > orange/results/environment-<ten>.txt
```
Ghi thêm CPU, RAM, hệ điều hành:
- Windows (PowerShell):
  ```powershell
  Get-CimInstance Win32_Processor | Select -Expand Name | Add-Content orange\results\environment-<ten>.txt
  "RAM GB: " + [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1) | Add-Content orange\results\environment-<ten>.txt
  (Get-CimInstance Win32_OperatingSystem).Caption | Add-Content orange\results\environment-<ten>.txt
  ```
- Linux: `lscpu | grep "Model name" >> orange/results/environment-<ten>.txt; free -g >> orange/results/environment-<ten>.txt; uname -a >> orange/results/environment-<ten>.txt`
- macOS: `sysctl -n machdep.cpu.brand_string >> orange/results/environment-<ten>.txt; sysctl -n hw.memsize >> orange/results/environment-<ten>.txt; sw_vers >> orange/results/environment-<ten>.txt`

**Bước 6 — Giữ máy thức**
- Windows: mở **một cửa sổ PowerShell riêng**, để chạy suốt: `powershell -NoProfile -ExecutionPolicy Bypass -File orange\scripts\keep_awake.ps1`
- macOS: mở thêm một terminal chạy `caffeinate -dimsu`.
- Linux: tắt chế độ ngủ trong cài đặt nguồn.

**Bước 7 — Thử nhanh trước khi chạy dài** (khoảng 1 phút)
```bash
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1      # Windows PowerShell: $env:JULIA_NUM_THREADS="1"; $env:OPENBLAS_NUM_THREADS="1"
julia --project=orange orange/scripts/run_experiments.jl 2 60 1 1 pc 1 1 -smoke
python orange/scripts/check_range.py orange/results/setA-01-P2-pc-smoke.csv 1 1
```
Mong đợi dòng cuối: `COMPLETE: du cac lan 1..1, tat ca check=ok`. Nếu không: dừng và báo nhóm. File `-smoke` không dùng trong kết quả chính thức.

---

## 4. Chạy phần việc của bạn

### Quy tắc bắt buộc
1. **Chỉ một tiến trình Julia tại một thời điểm.** Chạy hai cùng lúc có thể làm hết RAM.
2. **Chạy theo đúng thứ tự trong bảng, từng lệnh một**, mỗi lệnh **một lần**. Không chạy lại lệnh đã xong (nó ghi đè file kết quả).
3. **Chạy ở chế độ nền** và ghi log ra file (mẫu bên dưới); không đóng cửa sổ terminal nếu bạn chạy ở tiền cảnh.
4. Luôn đặt `JULIA_NUM_THREADS=1` và `OPENBLAS_NUM_THREADS=1` trước khi chạy (xem bước 7).
5. Nếu RAM trống xuống dưới **~3 GB**, hoặc lệnh báo lỗi: **dừng và báo nhóm**. Đừng thử lại nhiều lần.

### Lệnh của M2

| # | Lệnh | Log |
|---|---|---|
| 1 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 6 6 1500000 cg pc lns 900` | `log-opt-P2-06.txt` |
| 2 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 9 9 1500000 cg pc lns 900` | `log-opt-P2-09.txt` |
| 3 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 11 11 1500000 cg pc lns 900` | `log-opt-P2-11.txt` |
| 4 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 12 12 1500000 cg pc lns 900` | `log-opt-P2-12.txt` |
| 5 | `julia --project=orange orange/scripts/run_wp.jl 1 1800 10 10 1500000 cg pc lns 900` | `log-opt-P1-10.txt` |
| 6 | `julia --project=orange orange/scripts/run_wp.jl 1 1800 13 13 1500000 cg pc lns 900` | `log-opt-P1-13.txt` |

### Lệnh của M3

| # | Lệnh | Log |
|---|---|---|
| 1 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 18 18 1500000 cg pc lns 900` | `log-opt-P2-18.txt` |
| 2 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 14 14 1500000 cg pc lns 900` | `log-opt-P2-14.txt` |
| 3 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 15 15 1500000 cg pc lns 900` | `log-opt-P2-15.txt` |
| 4 | `julia --project=orange orange/scripts/run_wp.jl 1 1800 14 14 1500000 cg pc lns 900` | `log-opt-P1-14.txt` |

Ý nghĩa tham số: `run_wp.jl <P> <giới_hạn_giây> <instance> <instance> 1500000 cg pc lns 900`. `P=1`: chỉ thời kỳ 0; `P=2`: thời kỳ 0 và 1 có ngân sách. `cg`: sinh cột. `pc`: công thức tính hệ số tách của `calculating_r.pdf` (thầy yêu cầu). `lns 900`: tinh chỉnh LNS 900 giây.

### Cách chạy nền

- **Linux/macOS** (thay `<lệnh>` và `<log>` theo bảng):
  ```bash
  nohup <lệnh> > orange/results/<log> 2>&1 &
  ```
  Ví dụ M2 lệnh 1: `nohup julia --project=orange orange/scripts/run_wp.jl 2 3600 6 6 1500000 cg pc lns 900 > orange/results/log-opt-P2-06.txt 2>&1 &`
- **Windows (PowerShell):** cách đơn giản nhất là mở một cửa sổ PowerShell riêng và chạy lệnh ở tiền cảnh, **không đóng cửa sổ**, ghi log bằng:
  ```powershell
  julia --project=orange orange/scripts/run_wp.jl 2 3600 6 6 1500000 cg pc lns 900 *> orange\results\log-opt-P2-06.txt
  ```
  (hoặc dùng `Start-Process -NoNewWindow -FilePath julia -ArgumentList '--project=orange','orange/scripts/run_wp.jl','2','3600','6','6','1500000','cg','pc','lns','900' -RedirectStandardOutput orange/results/log-opt-P2-06.txt -RedirectStandardError orange/results/log-opt-P2-06.err`).

### Kiểm tra khi một lệnh xong

Thay đường dẫn cho đúng lệnh vừa chạy (ví dụ setA-09, `P2`):
```bash
python -c "import csv,sys; [print(r['instance'],r['P'],r['status'],r['mlu'],r['check']) for r in csv.DictReader(open(sys.argv[1]))]" orange/results/setA-09-wp-P2-cg-pc-lns.csv
```
**Mong đợi:** đúng một dòng, cột cuối (`check`) bắt đầu bằng `ok`. File kết quả có tên `setA-<XX>-wp-P<P>-cg-pc-lns.csv` (kèm `-loads.csv`, `-srpaths.json`); tên này **không trùng** file nào đã có trong repo.

- MLU **nhỏ hơn** giá trị trong `orange/results/best_known.csv` → **có ích**.
- MLU bằng hoặc kém hơn → **vẫn giữ file** (bằng chứng đã thử), không xoá, không chạy lại.
- **Đừng tự sửa bảng hay `best_known.csv`**: M1 sẽ gộp và tạo lại bảng.

### Theo dõi khi đang chạy

- File kết quả của một lệnh chỉ xuất hiện **khi lệnh đó xong** (từ vài phút đến khoảng 1,5 giờ); đọc `orange/results/log-opt-*.txt` để xem tiến độ. **Không có file trong lúc đang chạy là bình thường.**
- Tiến trình còn sống: Windows `Get-Process julia | Select Id,CPU,WorkingSet64`; Linux/macOS `ps aux | grep julia`.
- Kiểm tra RAM trống mỗi 20–30 phút; đừng kiểm tra dày hơn, đừng chạy lệnh nặng khác trong lúc đó.

---

## 5. Đẩy kết quả lên nhánh riêng của bạn

Sau **mỗi lệnh xong** (hoặc khi bạn phải dừng sớm), chạy (`<ten>` là `m2` hoặc `m3`):
```bash
python orange/scripts/publish_member_results.py <ten> --dry-run     # xem trước sẽ thêm những file nào
python orange/scripts/publish_member_results.py <ten>                 # tạo nhánh results/<ten>, commit, đẩy lên origin
```
- Script **chỉ** thêm file kết quả mới của bạn (`setA-*-wp-*-cg-pc-lns*`, `log-*.txt`, `environment-<ten>.txt`), **không** đụng `main` hay `feature/tasr`, không dùng `--force`. Mỗi người một nhánh nên không bao giờ xung đột.
- Thành công: in `Da dua ket qua len origin/results/<ten>`. Nhắn nhóm: "đã đẩy lệnh ...".
- `PUSH BI TU CHOI` (chưa có quyền ghi): kết quả vẫn nằm trong commit cục bộ; chạy `python orange/scripts/pack_member_results.py <ten>` để tạo `member_results/<ten>_<ngày_giờ>.zip` và **gửi file zip cho M1** (chat/Drive).
- Script **từ chối chạy** nếu bạn lỡ sửa file mã nguồn: hoàn tác thay đổi đó (`git checkout -- <file>`, chỉ với file bạn lỡ sửa) rồi chạy lại.
- Đây là thao tác git **duy nhất** bạn được làm (ngoài `clone`, `checkout feature/tasr`, `fetch`, `show`, `log`, `status`).
- **Sau lần đẩy đầu tiên, repo của bạn đang ở nhánh `results/<ten>`** (không phải `feature/tasr`). Đây là bình thường: các lệnh Julia vẫn chạy, và các lần đẩy sau **thêm** file mới vào cùng nhánh đó. Đã thử: đẩy lần 2, lần 3 đều chạy đúng; nếu bạn sửa nhầm file mã nguồn thì script từ chối và nêu tên file.

---

## 6. Khi có sự cố

| Tình huống | Làm gì |
|---|---|
| Máy ngủ hoặc tắt giữa chừng | Xem lệnh nào đã có file `setA-XX-wp-P<P>-cg-pc-lns.csv`. Chạy lại **chỉ các lệnh chưa có file** (và lệnh đang dở). Báo nhóm. |
| Julia hết bộ nhớ hoặc bị đóng | Đóng ứng dụng, chạy lại **lệnh dở** một lần. Báo nhóm. |
| Lệnh báo thiếu bộ nhớ hoặc bỏ qua instance | Kiểm tra RAM trống, đóng ứng dụng. Nếu vẫn thiếu: báo nhóm để chia lại. |
| `check` khác `ok`, `ERROR` hoặc status lạ | **Giữ nguyên file**, đẩy kết quả (mục 5) và báo nhóm kèm log; không tự chạy lại. |
| Không chắc điều gì | **Dừng** và hỏi nhóm; đừng tự đoán hay thử nhiều lần. |

---

## 7. Bạn đã xong khi

| Vai trò | Hoàn thành khi |
|---|---|
| **M2** | Có đủ 6 file `setA-06/09/11/12-wp-P2-cg-pc-lns.csv` và `setA-10/13-wp-P1-cg-pc-lns.csv`, mỗi file một dòng với `check` bắt đầu bằng `ok`; có `environment-m2.txt`; đã chạy `publish_member_results.py m2` thành công (hoặc đã gửi zip) |
| **M3** | Có đủ 4 file `setA-18/14/15-wp-P2-cg-pc-lns.csv` và `setA-14-wp-P1-cg-pc-lns.csv`, mỗi file một dòng với `check` bắt đầu bằng `ok`; có `environment-m3.txt`; đã chạy `publish_member_results.py m3` thành công (hoặc đã gửi zip) |

**Nếu hết thời gian** (hạn nhóm: T4), làm xong bao nhiêu thì đẩy bấy nhiêu; nhắn nhóm lệnh nào đã xong, lệnh nào chưa. Kết quả một phần vẫn có ích.

**Báo cáo cuối** (gửi nhóm, đúng mẫu):
```
Thành viên: M2 (hoặc M3)
Máy: CPU / RAM / HĐH (từ environment-<ten>.txt)
Commit đã clone: <git log -1 --oneline>
Với mỗi lệnh: lệnh đã chạy, đường dẫn CSV, dòng check (status, mlu, check), giờ bắt đầu và kết thúc, thời gian (solve_time), sự cố (máy ngủ, thiếu RAM, chạy lại)
Kết quả publish (nhánh results/<ten>) hoặc đường dẫn zip
Điều cần kiểm tra lại: ...
```
Hãy trung thực: ghi cả thất bại và kết quả một phần; **không** sửa hay bịa số liệu.

---

## 8. Nếu bạn dùng coding agent (Claude Code, Cursor, Codex, ...)

Mở thư mục repo bằng agent rồi gõ đúng một câu:

> **"Tôi là M2. Hãy đọc HUONG_DAN_M2_M3_FINAL.md và làm đúng phần việc của M2."** (hoặc "Tôi là M3 ...")

Quy tắc dành cho agent:
1. Làm **đúng file này, từng bước, theo thứ tự**; nếu chưa biết vai trò, hỏi "Bạn là M2 hay M3?".
2. **Cấm:** sửa/xoá/đổi tên file được theo dõi trong git; dùng git ngoài các lệnh ở mục 5; đẩy lên `main` hoặc `feature/tasr`; dùng `--force`; chạy hai tiến trình Julia nặng cùng lúc; chạy lại lệnh đã xong; đổi cài đặt hệ thống (ngoài việc khởi chạy `keep_awake.ps1` trên Windows).
3. Lệnh dài **phải chạy nền** với output ghi ra file; kiểm tra mỗi 20–30 phút; không busy-wait.
4. **Dừng và hỏi người dùng** khi: RAM trống < ~3 GB, Julia lỗi, `check` khác `ok`, status lạ, máy ngủ, hoặc điều gì không có trong file này.
5. Khi xong, viết báo cáo cuối theo mẫu mục 7.

Chi tiết dài hơn (nếu cần tra cứu): `START_HERE.md`, `project/AGENT_BRIEFS/`.

---

## 9. Làm song song: ai làm gì, khi nào

**Nguyên tắc để không vướng nhau:**

| Điều | M1 | M2 | M3 |
|---|---|---|---|
| Máy | máy của M1 | máy của M2 | máy của M3 |
| Việc | chạy nốt setA-04 và setA-05 ở $t=0,1$ (≈ 11 giờ, xong ~20:00) | 6 lệnh ở mục 4 | 4 lệnh ở mục 4 (+ phần thêm, mục 10) |
| File ghi ra | `orange/results/...-rK-K.csv` | `setA-{06,09,11,12}-wp-P2-...`, `setA-{10,13}-wp-P1-...` | `setA-{18,14,15}-wp-P2-...`, `setA-14-wp-P1-...` |
| Nhánh git đẩy | `feature/tasr` | `results/m2` | `results/m3` |

- **Không có phụ thuộc giữa các bên.** M2 và M3 **không** cần đợi M1, cũng không đợi nhau; M1 cũng không đợi họ.
- **Không trùng file:** mỗi người ghi file của riêng mình (tên theo instance, khác nhau), đẩy lên nhánh riêng nên không bao giờ xung đột git.
- **Bạn chỉ cần liên lạc khi:** (1) xong một lệnh (một dòng: "đã đẩy lệnh X"), (2) có sự cố (mục 6), (3) xong hết hoặc phải dừng sớm.

**Mốc thời gian gợi ý (hôm nay Thứ Ba 20/10):**

| Mốc | Việc |
|---|---|
| Ngay bây giờ → ~1 giờ | Chuẩn bị máy (mục 3) |
| Sau đó → tối | Chạy các lệnh mục 4, đẩy kết quả sau **mỗi** lệnh xong |
| ~20:00 20/10 | M1 gộp lần 1 (có kết quả nào thì gộp vào đó) |
| Đêm 20 → sáng 21/10 | Máy vẫn có thể chạy tiếp các lệnh còn lại |
| ~12:00 sáng T4 (21/10) | M1 gộp lần cuối, tạo lại bảng, chốt `main`. **Kết quả đẩy sau mốc này có thể không kịp** |

Nếu máy của bạn không chạy suốt đêm: ưu tiên các lệnh **đứng đầu bảng** (đã xếp theo mức ưu tiên); phần chưa xong không sao, báo nhóm là được.

---

## 10. Nếu bạn xong sớm

1. Kiểm tra mục 7 (đủ file, `check=ok`, đã đẩy), gửi báo cáo cuối.
2. **Phần thêm tuỳ chọn** (chỉ M3, chỉ khi RAM trống ≥ 12 GB và bạn đã xong hết danh sách chính; **chưa đo RAM đỉnh**, dừng nếu RAM trống < 3 GB):
   ```bash
   julia --project=orange orange/scripts/run_wp.jl 1 1800 19 19 1500000 cg pc lns 900     # log: log-opt-P1-19.txt
   ```
   Nguồn gốc: setA-19 ở Bảng 1 còn gap 2,7 % và chưa được LNS. Kiểm tra và đẩy kết quả như mục 4 và 5. Nếu M3 không làm, M1 sẽ làm sau khi chạy xong phần của mình.
3. **Không tự chọn thêm instance khác**: các instance còn lại hoặc đã tối ưu (setA-07, 08, 17, 20 ở $t=0,1$ và hầu hết instance ở $t=0$) hoặc nặng RAM (setA-16, 19 ở $t=0,1$) và do M1 phụ trách. Có thắc mắc thì hỏi nhóm.
4. Nếu M2 xong sớm: báo nhóm là đã xong; M2 **không** có phần thêm.

---

## 11. Kết quả của bạn được dùng ra sao (để hiểu việc của mình)

- Mô hình theo cung của thầy chỉ nạp được 5 instance đầu; các instance lớn dùng **mô hình waypoint** (mỗi nhu cầu đi tối đa qua 1 waypoint). Các dòng đó ghi `*` trong bảng.
- Lệnh của bạn chạy mô hình waypoint **kèm LNS** (tinh chỉnh nghiệm) trên các dòng chưa được LNS, để **thử hạ MLU**.
- M1 gộp kết quả: `merge_member_branch.py` → `best_known.jl` chọn MLU **nhỏ nhất** trong mọi file của từng instance → `official_tables.jl` tạo lại hai bảng → `verify_srpaths.py` kiểm chứng độc lập từng lời giải → tạo manifest SHA-256.
- Vì thế: **MLU kém hơn không làm hỏng gì** (bảng luôn lấy giá trị tốt nhất); file của bạn là **bằng chứng đã thử**, giữ nguyên.
- Kết quả của bạn **không** đổi hàng dùng mô hình của thầy (`arc-pc`); nó chỉ cải thiện các dòng `*` và cột "Tốt nhất biết được".
- Số liệu trong bảng đều được kiểm chứng độc lập; bạn **đừng** sửa bảng hay `best_known.csv`.
