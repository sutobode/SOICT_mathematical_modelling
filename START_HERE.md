# START HERE — Hướng dẫn từng bước cho thành viên M2 và M3

> Bạn chỉ cần **link git này**. Mọi thứ cần làm đã nằm trong repo. Tài liệu viết sao cho **bạn (hoặc coding agent của bạn) làm theo đúng từng bước là chạy được**, không cần hỏi ai. Thời gian tổng: khoảng **9 giờ** (chủ yếu là máy tự chạy), công sức của bạn khoảng **30 phút** lúc đầu và vài lần kiểm tra.
>
> Nếu bạn dùng **coding agent** (Claude Code, Cursor, Codex, Copilot Agent, ...): mở thư mục repo bằng agent rồi gõ đúng một câu:
> **"Tôi là M2. Hãy đọc START_HERE.md và làm đúng phần việc của M2."** (hoặc "Tôi là M3 ...").
> Agent đọc file này và thực hiện từng bước; mục 14 dành riêng cho agent.

## 0. Dự án này là gì (30 giây)

Đồ án SOICT: bài toán **T-Adaptive Segment Routing** (Challenge ROADEF/EURO 2026, Orange). Mã nguồn Julia (JuMP + HiGHS) trong thư mục `orange/`, dữ liệu 20 instance trong `project/setA/`. Thầy yêu cầu **trung bình trên 10 lần chạy** (seed 1 đến 10) cho mỗi dòng của hai bảng kết quả. Một số lần chạy rất lâu (khoảng 1 giờ mỗi lần), nên chia cho 3 máy, **mỗi máy chạy một khoảng seed riêng, không giao nhau**. Việc của bạn: **chạy đúng khoảng được giao**, kiểm tra, rồi đẩy kết quả lên nhánh riêng của bạn.

## 1. Bạn là ai và làm gì (chọn đúng một dòng)

| Vai trò | Việc 1 | Việc 2 | Việc 3 | Tổng thời gian |
|---|---|---|---|---|
| **M2** | setA-04, $t=0,1$, seed **5 đến 7** (~3,2 giờ) | setA-05, $t=0,1$, seed **6 đến 8** (~3,3 giờ; chỉ nếu pilot của M1 thành công) | — | ~6,5 giờ |
| **M3** | setA-04, $t=0,1$, seed **8 đến 10** (~3,2 giờ) | setA-05, $t=0,1$, seed **9 đến 10** (~2,2 giờ; chỉ nếu pilot của M1 thành công) | — | ~5,4 giờ |

(**M1** là người điều phối: chạy setA-04 $t=0,1$ seed 1–4 và **setA-05 $t=0,1$ seed 1–5** (làm pilot) trên máy riêng trong đêm 19→20/10, cùng các dòng khác; bạn không cần làm gì cho M1.) Không ai khác chạy các khoảng seed của bạn; **đừng đổi khoảng seed, tên file hay thứ tự**.

**Quy ước tên:** lệnh có tham số `P=2` nghĩa là "thời kỳ 0 và 1 có ngân sách" (giới hạn 3600 s mỗi lần); `pc` nghĩa là dùng công thức tính hệ số tách của `calculating_r.pdf` (thầy yêu cầu).

## 2. Điều kiện máy (kiểm tra trước khi bắt đầu)

| Yêu cầu | setA-04 | setA-05 |
|---|---|---|
| RAM tổng | ≥ 16 GB | ≥ 24 GB (khuyến nghị) |
| RAM **trống** trong lúc chạy | ≥ 12 GB | ≥ 16 GB |
| Ổ cứng trống | ≥ 2 GB | |

- **Nếu máy chỉ có 16 GB:** bạn chỉ nhận phần setA-04. Với M2: làm Việc 2 và bỏ Việc 1 và 3; với M3: làm Việc 1 và bỏ Việc 2. Nhắn cho nhóm để M1 biết.
- Đóng **trình duyệt và mọi ứng dụng nặng**; cắm sạc; tắt chế độ ngủ; không chạy việc nặng khác khi đang chạy (thời gian là số liệu nộp).
- Hệ điều hành: Windows, Linux hoặc macOS đều được.

## 3. Bước 1 — Lấy mã nguồn

```bash
git clone https://github.com/sutobode/SOICT_mathematical_modelling.git soict
cd soict
git checkout feature/tasr          # nhánh có đủ tài liệu và script (KHÔNG làm việc trên main)
git log -1 --oneline               # ghi lại commit này vào báo cáo của bạn
```
Nếu `git clone` báo không có quyền, nhờ chủ repo (sutobode) thêm bạn làm collaborator, hoặc xin file `member_kit_*.zip` thay thế (giải nén ra thư mục `soict`; khi đó bước đẩy kết quả dùng file zip, xem mục 11).

**Từ đây, mọi lệnh chạy từ thư mục `soict` (gốc repo).**

## 4. Bước 2 — Cài Julia 1.13.1 và Python 3

- **Julia 1.13.1** (đúng phiên bản):
  - Windows: `winget install --id Julialang.Juliaup -e`, mở lại terminal, rồi `juliaup add 1.13.1` và `juliaup default 1.13.1`.
  - Linux/macOS: `curl -fsSL https://install.julialang.org | sh`, mở lại terminal, rồi `juliaup add 1.13.1` và `juliaup default 1.13.1`.
  - Kiểm tra: `julia --version` phải in `julia version 1.13.1`.
- **Python 3** (bản nào từ 3.9 trở lên): kiểm tra `python --version` (Linux/macOS có thể là `python3`).
- **git**: đã có vì bạn vừa clone.

## 5. Bước 3 — Kiểm tra máy (1 phút)

```bash
python orange/scripts/preflight.py
```
Phải thấy các dòng `[OK   ]` cho Julia, dữ liệu (60 file) và script, và phần "Ket luan" cho biết máy nhận được việc nào:
- `setA-04 ... CO THE nhan` → nhận được;
- `setA-05 ... CHUA du RAM trong` → đóng thêm ứng dụng và chạy lại; vẫn chưa đủ thì **không nhận setA-05**.

## 6. Bước 4 — Cài thư viện và chạy bộ test (khoảng 5–15 phút, lần đầu lâu hơn vì biên dịch)

```bash
julia --project=orange -e "using Pkg; Pkg.instantiate()"
julia --project=orange orange/test/runtests.jl
```
**Kết quả mong đợi:** các dòng `Test Summary: ... Pass ...` và **không có** dòng `Fail` hay `Error`. Nếu có, **dừng lại** và báo nhóm kèm 30 dòng cuối của output.

## 7. Bước 5 — Ghi lại môi trường máy (bắt buộc, để thầy truy vết)

Thay `<ten>` bằng `m2` hoặc `m3`:
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

## 8. Bước 6 — Giữ máy thức

- Windows: mở **một cửa sổ PowerShell riêng** và để chạy suốt:
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File orange\scripts\keep_awake.ps1
  ```
  Cắm sạc, **không gập nắp laptop**.
- Linux: `systemctl mask sleep.target suspend.target` cần quyền root; hoặc dùng `caffeinate`-tương đương của môi trường; tối thiểu: tắt chế độ ngủ trong cài đặt nguồn.
- macOS: mở thêm một terminal chạy `caffeinate -dimsu`.

(Máy đã từng bị ngủ giữa chừng làm hỏng một số lần chạy trên máy M1.)

## 9. Bước 7 — Kiểm tra nhanh trước khi chạy dài (khoảng 1 phút)

```bash
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1          # Windows PowerShell: $env:JULIA_NUM_THREADS="1"; $env:OPENBLAS_NUM_THREADS="1"
julia --project=orange orange/scripts/run_experiments.jl 2 60 1 1 pc 1 1 -smoke
python orange/scripts/check_range.py orange/results/setA-01-P2-pc-smoke.csv 1 1
```
**Mong đợi:** dòng cuối `COMPLETE: du cac lan 1..1, tat ca check=ok` (setA-01 giải xong trong khoảng 40 giây, status `Optimal`). Nếu không, dừng lại và báo nhóm. File `-smoke` không được dùng trong bảng chính thức.

## 10. Bước 8 — Chạy phần việc của bạn

**Quy tắc bắt buộc:**
1. **Chỉ một tiến trình Julia nặng tại một thời điểm.** Mỗi lần setA-04 ($t=0,1$) cần khoảng 8 GB RAM đỉnh; setA-05 khoảng 11 đến 14 GB. Chạy hai tiến trình cùng lúc sẽ làm hết RAM (đã làm mất một lần chạy của M1).
2. **Chạy từng lệnh ở chế độ nền** (một lần chạy khoảng 1 giờ), ghi output ra file log (mẫu bên dưới), **đừng đóng terminal** nếu bạn chạy ở nền của terminal.
3. **Không chạy lại một khoảng đã có file CSV** (lệnh ghi đè file). Gián đoạn giữa chừng: xem mục 13.
4. Không sửa bất kỳ file nào của dự án; chỉ tạo file mới trong `orange/results/`.

Cú pháp: `run_experiments.jl <P> <giới_hạn_giây> <instance_đầu> <instance_cuối> pc <seed_đầu> <seed_cuối> <hậu_tố>`.

**Mẫu chạy nền** (thay lệnh `julia ...` bằng lệnh của việc đang làm):
- Linux/macOS: `nohup julia --project=orange orange/scripts/run_experiments.jl <tham số> > orange/results/<log>.txt 2>&1 &`
- Windows (PowerShell):
  ```powershell
  Start-Process -NoNewWindow -FilePath julia -ArgumentList '--project=orange','orange/scripts/run_experiments.jl','<tham','số...>' -RedirectStandardOutput orange/results/<log>.txt -RedirectStandardError orange/results/<log>.err
  ```
  (hoặc đơn giản: mở một cửa sổ PowerShell riêng và chạy lệnh ở tiền cảnh, không đóng cửa sổ.)

### Nếu bạn là M2

| # | Lệnh | Log | Kiểm tra khi xong |
|---|---|---|---|
| 1 | `julia --project=orange orange/scripts/run_experiments.jl 2 3600 4 4 pc 5 7 -r5-7` | `log-pc-P2-04-r5-7.txt` | `python orange/scripts/check_range.py orange/results/setA-04-P2-pc-r5-7.csv 5 7` |
| 2 | `julia --project=orange orange/scripts/run_experiments.jl 2 3600 5 5 pc 6 8 -r6-8` | `log-pc-P2-05-r6-8.txt` | `python orange/scripts/check_range.py orange/results/setA-05-P2-pc-r6-8.csv 6 8` |

**Trước lệnh 2 (setA-05)**, kiểm tra pilot của M1 (M1 đẩy kết quả lên nhánh `feature/tasr`; không cần hỏi ai):
```bash
git fetch origin feature/tasr
git ls-tree --name-only origin/feature/tasr orange/results/ | grep "setA-05-P2-pc"        # tìm file kết quả setA-05 t=0,1 của M1 (thường setA-05-P2-pc-r1-5.csv)
git show origin/feature/tasr:orange/results/setA-05-P2-pc-r1-5.csv | python orange/scripts/check_range.py - 1 1 --subset
```
- In `COMPLETE` (mã thoát 0): pilot thành công → chạy lệnh 2 (cần RAM trống ≥ 16 GB và máy ≥ 24 GB RAM; xem bước 3).
- Không thấy file hoặc `fatal: path ... does not exist`: M1 **chưa** đẩy pilot → chờ rồi thử lại sau 30 phút (nếu sau 3 giờ vẫn không có, bỏ qua lệnh 2 và nhắn nhóm).
- `PROBLEM`: pilot **thất bại** → **bỏ lệnh 2** (setA-05 giữ nghiệm waypoint), ghi chú trong báo cáo của bạn.
- Nếu máy báo `SKIPPED_LOW_MEMORY` dù RAM trống thật ≥ 14 GB, chạy lại **đúng lệnh 2** thêm tham số cuối `14` (ngân sách bộ nhớ GB), **một lần**.

### Nếu bạn là M3

| # | Lệnh | Log | Kiểm tra khi xong |
|---|---|---|---|
| 1 | `julia --project=orange orange/scripts/run_experiments.jl 2 3600 4 4 pc 8 10 -r8-10` | `log-pc-P2-04-r8-10.txt` | `python orange/scripts/check_range.py orange/results/setA-04-P2-pc-r8-10.csv 8 10` |
| 2 | `julia --project=orange orange/scripts/run_experiments.jl 2 3600 5 5 pc 9 10 -r9-10` | `log-pc-P2-05-r9-10.txt` | `python orange/scripts/check_range.py orange/results/setA-05-P2-pc-r9-10.csv 9 10` |

**Trước lệnh 2 (setA-05)**, kiểm tra pilot của M1 bằng đúng ba lệnh ở mục "Nếu bạn là M2" (nhánh `feature/tasr`, kết quả setA-05 $t=0,1$ của M1). Quy tắc quyết định giống M2.

## 11. Bước 9 — Theo dõi khi đang chạy

- CSV của một khoảng chỉ xuất hiện **sau khi lần chạy đầu tiên của khoảng đó xong** (khoảng 1 giờ với setA-04, hơn thế với setA-05); **không có file trong giờ đầu là bình thường**.
- Tiến trình còn sống: Windows `Get-Process julia | Select Id,CPU,WorkingSet64` (RAM ~6–8 GB cho setA-04; CPU tăng đều); Linux/macOS `ps aux | grep julia`.
- Tiến độ: `python orange/scripts/check_range.py <file.csv> <seed_đầu> <seed_cuối>` ở bất kỳ lúc nào: in từng lần chạy xong và các lần còn thiếu (`INCOMPLETE`).
- Log solver nguyên văn của từng lần chạy: `orange/results/solverlogs/setA-04-P2-pc-r5-7-run5.log` (và `run6`, `run7`).
- Kiểm tra RAM trống ít nhất mỗi 30 phút (Task Manager hoặc `free -g`); nếu dưới 3 GB, đóng bớt ứng dụng.
- **Đừng kiểm tra quá dày** (mỗi 20–30 phút là đủ); đừng chạy lệnh nặng khác trong lúc đó.

## 12. Bước 10 — Đẩy kết quả lên nhánh riêng của bạn

Sau **mỗi khoảng xong**, chạy:
```bash
python orange/scripts/publish_member_results.py <ten> --dry-run     # xem trước sẽ thêm những file nào
python orange/scripts/publish_member_results.py <ten>                 # tạo nhánh results/<ten>, commit, đẩy lên origin
```
(`<ten>` là `m2` hoặc `m3`.) Script **chỉ** thêm file kết quả mới của bạn (CSV các khoảng, log solver, log chạy, `environment-<ten>.txt`), **từ chối** chạy nếu bạn lỡ sửa file mã nguồn, **không** đụng tới `main` hay `feature/tasr`, không bao giờ dùng `--force`. Mỗi thành viên một nhánh riêng nên không bao giờ xung đột.

- Thành công: in `Da dua ket qua len origin/results/<ten>`. Báo nhóm: "đã đẩy khoảng ...".
- `PUSH BI TU CHOI`: bạn chưa có quyền ghi. Kết quả đã nằm trong commit cục bộ; chạy `python orange/scripts/pack_member_results.py <ten>` để tạo file `member_results/<ten>_<ngày_giờ>.zip` và **gửi file zip cho M1** (qua chat/Drive).
- **Đây là thao tác git duy nhất bạn được làm** (ngoài `clone`, `checkout feature/tasr`, `fetch`, `show`).

## 13. Khi có sự cố

| Tình huống | Làm gì |
|---|---|
| Máy ngủ/tắt giữa chừng | Xem file CSV của khoảng đó có bao nhiêu lần xong (`check_range.py`). Chạy **phần còn lại** bằng **khoảng con và hậu tố mới**. Ví dụ khoảng `-r5-7` mới xong seed 5: chạy `... pc 6 7 -r6-7`. **Không** chạy lại `-r5-7`. |
| Julia hết bộ nhớ hoặc bị đóng | Đóng ứng dụng, chạy lại **phần chưa xong** bằng khoảng con và hậu tố mới. Báo nhóm. |
| `status = SKIPPED_LOW_MEMORY` ở setA-04 | Kiểm tra RAM trống, đóng ứng dụng, chạy lại preflight. Nếu vẫn thiếu: báo nhóm để chia lại cho máy khác. |
| `check` khác `ok`, `ERROR` hoặc status lạ | **Giữ nguyên file**, đẩy kết quả (bước 10) và báo nhóm kèm log; không tự chạy lại. |
| `check_range` báo `PROBLEM: trung so lan chay` | Báo nhóm ngay (có thể bị chồng khoảng). |
| `publish_member_results.py` từ chối vì file bị sửa | Hoàn tác thay đổi của bạn (`git checkout -- <file>` **chỉ cho file bạn lỡ sửa**), chạy lại. |
| Không chắc điều gì | **Dừng** và hỏi nhóm; đừng tự đoán hay thử nhiều lần. |

## 14. Dành cho coding agent

Nếu bạn là coding agent và người dùng nói họ là M2 hoặc M3:
1. **Đọc và làm theo đúng file này, từng bước, theo thứ tự.** Nếu người dùng chưa nói vai trò, hỏi: "Bạn là M2 hay M3?".
2. Chi tiết bổ sung và các quy tắc nghiêm ngặt dành cho agent: `project/AGENT_BRIEFS/00_NGU_CANH_CHUNG.md`, và khối PROMPT trong `project/AGENT_BRIEFS/M2_BRIEF.md` hoặc `M3_BRIEF.md`.
3. **Cấm:** sửa/xóa/đổi tên file được theo dõi trong git; dùng git ngoài các lệnh `clone`, `checkout feature/tasr`, `fetch`, `show` và lệnh `python orange/scripts/publish_member_results.py <ten>`; đẩy lên `main` hoặc `feature/tasr`; dùng `--force`; chạy hai tiến trình Julia nặng cùng lúc; chạy lại khoảng đã có CSV; thay đổi cài đặt hệ thống (ngoài việc khởi chạy `keep_awake.ps1`).
4. Lệnh dài (khoảng 1 giờ mỗi lần) **phải chạy nền** với output ghi ra file; kiểm tra mỗi 20–30 phút; không busy-wait.
5. **Dừng và hỏi người dùng** khi: thiếu RAM, Julia lỗi, `check` khác `ok`, status lạ, trùng seed, máy ngủ, hoặc bất cứ điều gì không có trong tài liệu này. Báo cáo trung thực, kể cả thất bại hay kết quả một phần; **không bao giờ** sửa hay bịa số liệu.
6. Khi xong, viết **báo cáo cuối** gồm: vai trò; máy (CPU/RAM/OS từ `environment-<ten>.txt`); với mỗi khoảng: lệnh đã chạy, đường dẫn CSV, kết quả `check_range.py`, giờ bắt đầu và kết thúc, thời gian mỗi lần chạy (cột `solve_time`), sự cố (máy ngủ, thiếu RAM, chạy lại); kết quả `publish_member_results.py` (hoặc đường dẫn zip); và điều người dùng nên kiểm tra lại.

## 15. Bạn đã xong khi

| Vai trò | Hoàn thành khi |
|---|---|
| **M2** | `check_range.py` báo `COMPLETE` cho `setA-04-P2-pc-r5-7.csv` (3 dòng) và `setA-05-P2-pc-r6-8.csv` (3 dòng; chỉ nếu pilot của M1 ổn); có `environment-m2.txt`; đã chạy `publish_member_results.py m2` thành công (hoặc đã gửi zip) |
| **M3** | `check_range.py` báo `COMPLETE` cho `setA-04-P2-pc-r8-10.csv` (3 dòng) và `setA-05-P2-pc-r9-10.csv` (2 dòng; chỉ nếu pilot của M1 ổn); có `environment-m3.txt`; đã chạy `publish_member_results.py m3` thành công (hoặc đã gửi zip) |

Cuối cùng nhắn nhóm: "M2/M3 xong, đã đẩy lên `results/m2` (hoặc `results/m3`)". M1 sẽ gộp, kiểm chứng và cập nhật bảng kết quả.

## 16. Tài liệu tham khảo trong repo

- `project/HUONG_DAN_CHAY_SONG_SONG.md` — kế hoạch phân công đầy đủ của 3 máy.
- `project/AGENT_BRIEFS/` — các bản giao việc chi tiết cho coding agent.
- `orange/README.md` — mã nguồn, cách chạy, các quyết định thiết kế.
- `orange/results/README_KET_QUA.md` và `orange/results/RUN_JOURNAL.md` — cách đọc kết quả và nhật ký các lần chạy.
