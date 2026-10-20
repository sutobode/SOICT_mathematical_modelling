# START HERE — Hướng dẫn từng bước cho thành viên M2 và M3

> **BẢN CHÍNH THỨC NGẮN GỌN: `HUONG_DAN_M2_M3_FINAL.md`. Nếu có chỗ khác với file này, làm theo `HUONG_DAN_M2_M3_FINAL.md`.** File này chỉ là bản chi tiết để tra cứu.

> **CẬP NHẬT 20/10 ~10:00 — PHÂN CÔNG HIỆN HÀNH (đọc trước, thay thế mọi phân công cũ):**
> - **M1** chạy **toàn bộ** các lần còn thiếu của Bảng 2: setA-04 $t=0,1$ lần 5–10 và setA-05 $t=0,1$ seed 6–10 (dự kiến xong ~20:00 20/10). **M2 và M3 KHÔNG chạy các lần này.**
> - **M2 và M3** chạy **các thử nghiệm cải tiến tối ưu** (mô hình waypoint + LNS) trên các instance **khác nhau** được ghi ở mục 1 và mục 10 bên dưới. Danh sách này không giao với phần của M1 và không giao nhau giữa M2 và M3.
> - Nếu bạn đã chạy xong một khoảng setA-04/05 từ trước theo phân công cũ, vẫn đẩy kết quả bằng `publish_member_results.py` (bộ gộp bảng giữ bản đầu và báo trùng); không chạy thêm.
> - Giải thích vì sao chọn các instance này: `project/DE_XUAT_CAI_TIEN_TOI_UU.md`.

> Bạn chỉ cần **link git này**. Mọi thứ cần làm đã nằm trong repo. Tài liệu viết sao cho **bạn (hoặc coding agent của bạn) làm theo đúng từng bước là chạy được**, không cần hỏi ai. Thời gian tổng: khoảng **3 đến 6 giờ** (chủ yếu là máy tự chạy), công sức của bạn khoảng **30 phút** lúc đầu và vài lần kiểm tra.
>
> Nếu bạn dùng **coding agent** (Claude Code, Cursor, Codex, Copilot Agent, ...): mở thư mục repo bằng agent rồi gõ đúng một câu:
> **"Tôi là M2. Hãy đọc START_HERE.md và làm đúng phần việc của M2."** (hoặc "Tôi là M3 ...").
> Agent đọc file này và thực hiện từng bước; mục 14 dành riêng cho agent.

## 0. Dự án này là gì (30 giây)

Đồ án SOICT: bài toán **T-Adaptive Segment Routing** (Challenge ROADEF/EURO 2026, Orange). Mã nguồn Julia (JuMP + HiGHS) trong thư mục `orange/`, dữ liệu 20 instance trong `project/setA/`. Thầy yêu cầu **trung bình trên 10 lần chạy** cho mỗi dòng của hai bảng kết quả; M1 đang chạy các lần còn thiếu của hai instance lớn nhất. Việc của bạn (M2/M3): chạy các **thử nghiệm cải tiến tối ưu** (hạ MLU của một số dòng chưa được tinh chỉnh) trên **nhóm instance được giao riêng cho bạn**, kiểm tra, rồi đẩy kết quả lên nhánh riêng của bạn.

## 1. Bạn là ai và làm gì (chọn đúng một dòng)

| Vai trò | Bảng 2 ($t=0,1$, `P=2`, 3600 s + LNS 900 s) | Bảng 1 ($t=0$, `P=1`, 1800 s + LNS 900 s) | Tổng thời gian ước tính |
|---|---|---|---|
| **M2** | setA-**06, 09, 11, 12** | setA-**10, 13** | ~4–6 giờ |
| **M3** | setA-**14, 15, 18** | setA-**14** | ~3–5 giờ |

(**M1** chạy toàn bộ các lần còn thiếu của setA-04 và setA-05 ở $t=0,1$ trên máy riêng; bạn không cần làm gì cho M1.) Hai nhóm instance của M2 và M3 **không giao nhau**. **Đừng đổi instance, tên file hay thứ tự.** Mỗi instance chạy **một lần**; mục tiêu là hạ MLU, không phải lấy trung bình.

**Quy ước tên:** lệnh có tham số `P=1` là chỉ thời kỳ 0 (giới hạn 1800 s) và `P=2` là "thời kỳ 0 và 1 có ngân sách" (3600 s); `pc` nghĩa là dùng công thức tính hệ số tách của `calculating_r.pdf` (thầy yêu cầu).

## 2. Điều kiện máy (kiểm tra trước khi bắt đầu)

| Yêu cầu | Giá trị |
|---|---|
| RAM tổng | ≥ 16 GB |
| RAM **trống** trong lúc chạy | ≥ 8 GB (chưa đo đỉnh RAM của các instance này; dừng nếu xuống dưới ~3 GB) |
| Ổ cứng trống | ≥ 2 GB |

- Nếu máy yếu hơn: nhắn nhóm để M1 chia lại; **đừng tự đổi instance**.
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
Phải thấy các dòng `[OK   ]` cho Julia, dữ liệu (60 file) và script. (Dòng "Ket luan" về setA-04/setA-05 dành cho phân công cũ; **bỏ qua**. Bạn chỉ cần RAM trống ≥ 8 GB, xem mục 2.)

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
1. **Chỉ một tiến trình Julia nặng tại một thời điểm.** Chạy hai tiến trình cùng lúc có thể làm hết RAM (đã làm mất một lần chạy của M1).
2. **Chạy từng lệnh ở chế độ nền** (một lệnh có thể kéo dài đến khoảng 1,5 giờ), ghi output ra file log (mẫu bên dưới), **đừng đóng terminal** nếu bạn chạy ở nền của terminal.
3. **Không chạy lại một lệnh đã chạy xong** (lệnh ghi đè file kết quả của nó). Gián đoạn giữa chừng: xem mục 13.
4. Không sửa bất kỳ file nào của dự án; chỉ tạo file mới trong `orange/results/`.

Cú pháp: `run_wp.jl <P> <giới_hạn_giây> <instance> <instance> 1500000 cg pc lns 900` (`P`: 1 hoặc 2; `900` là số giây LNS).

**Mẫu chạy nền** (thay lệnh `julia ...` bằng lệnh của việc đang làm):
- Linux/macOS: `nohup julia --project=orange orange/scripts/run_wp.jl <tham số> > orange/results/<log>.txt 2>&1 &`
- Windows (PowerShell):
  ```powershell
  Start-Process -NoNewWindow -FilePath julia -ArgumentList '--project=orange','orange/scripts/run_wp.jl','<tham','số...>' -RedirectStandardOutput orange/results/<log>.txt -RedirectStandardError orange/results/<log>.err
  ```
  (hoặc đơn giản: mở một cửa sổ PowerShell riêng và chạy lệnh ở tiền cảnh, không đóng cửa sổ.)

### Nếu bạn là M2

| # | Lệnh | Log |
|---|---|---|
| 1 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 6 6 1500000 cg pc lns 900` | `log-opt-P2-06.txt` |
| 2 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 9 9 1500000 cg pc lns 900` | `log-opt-P2-09.txt` |
| 3 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 11 11 1500000 cg pc lns 900` | `log-opt-P2-11.txt` |
| 4 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 12 12 1500000 cg pc lns 900` | `log-opt-P2-12.txt` |
| 5 | `julia --project=orange orange/scripts/run_wp.jl 1 1800 10 10 1500000 cg pc lns 900` | `log-opt-P1-10.txt` |
| 6 | `julia --project=orange orange/scripts/run_wp.jl 1 1800 13 13 1500000 cg pc lns 900` | `log-opt-P1-13.txt` |

### Nếu bạn là M3

| # | Lệnh | Log |
|---|---|---|
| 1 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 18 18 1500000 cg pc lns 900` | `log-opt-P2-18.txt` |
| 2 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 14 14 1500000 cg pc lns 900` | `log-opt-P2-14.txt` |
| 3 | `julia --project=orange orange/scripts/run_wp.jl 2 3600 15 15 1500000 cg pc lns 900` | `log-opt-P2-15.txt` |
| 4 | `julia --project=orange orange/scripts/run_wp.jl 1 1800 14 14 1500000 cg pc lns 900` | `log-opt-P1-14.txt` |

**Phần thêm tuỳ chọn cho M3** (chỉ sau khi xong hết bảng, nếu RAM trống ≥ 12 GB): `julia --project=orange orange/scripts/run_wp.jl 1 1800 19 19 1500000 cg pc lns 900` (log `log-opt-P1-19.txt`); chi tiết ở `HUONG_DAN_M2_M3_FINAL.md` mục 10.

**Chạy theo đúng thứ tự trong bảng, từng lệnh một.** Mỗi lệnh sinh các file `orange/results/setA-XX-wp-P<P>-cg-pc-lns.csv` (cùng `-loads.csv`, `-srpaths.json`); tên không trùng file nào đã có trong repo.

**Kiểm tra khi một lệnh xong** (thay đường dẫn cho đúng lệnh vừa chạy):
```bash
python -c "import csv,sys; [print(r['instance'],r['P'],r['status'],r['mlu'],r['check']) for r in csv.DictReader(open(sys.argv[1]))]" orange/results/setA-09-wp-P2-cg-pc-lns.csv
```
Mong đợi: một dòng, `check` bắt đầu bằng `ok`. MLU nhỏ hơn giá trị hiện có trong `orange/results/best_known.csv` là **có ích**; bằng hoặc kém hơn vẫn **giữ file** (bằng chứng đã thử). **Đừng tự sửa bảng hay `best_known.csv`**: M1 sẽ gộp.

Chỉ cần thêm: nếu RAM trống xuống dưới ~3 GB hoặc lệnh lỗi, **dừng và báo nhóm**.

## 11. Bước 9 — Theo dõi khi đang chạy

- File kết quả của một lệnh chỉ xuất hiện **khi lệnh đó xong** (từ vài phút đến khoảng 1,5 giờ); đọc `orange/results/log-opt-*.txt` để xem tiến độ.
- Tiến trình còn sống: Windows `Get-Process julia | Select Id,CPU,WorkingSet64` (CPU tăng đều); Linux/macOS `ps aux | grep julia`.
- Kiểm tra RAM trống ít nhất mỗi 30 phút (Task Manager hoặc `free -g`); nếu dưới 3 GB, đóng bớt ứng dụng.
- **Đừng kiểm tra quá dày** (mỗi 20–30 phút là đủ); đừng chạy lệnh nặng khác trong lúc đó.

## 12. Bước 10 — Đẩy kết quả lên nhánh riêng của bạn

Sau **mỗi khoảng xong**, chạy:
```bash
python orange/scripts/publish_member_results.py <ten> --dry-run     # xem trước sẽ thêm những file nào
python orange/scripts/publish_member_results.py <ten>                 # tạo nhánh results/<ten>, commit, đẩy lên origin
```
(`<ten>` là `m2` hoặc `m3`.) Script **chỉ** thêm file kết quả mới của bạn (file `setA-*-wp-*-cg-pc-lns*`, log chạy `log-*.txt`, `environment-<ten>.txt`), **từ chối** chạy nếu bạn lỡ sửa file mã nguồn, **không** đụng tới `main` hay `feature/tasr`, không bao giờ dùng `--force`. Mỗi thành viên một nhánh riêng nên không bao giờ xung đột.

- Thành công: in `Da dua ket qua len origin/results/<ten>`. Báo nhóm: "đã đẩy khoảng ...".
- `PUSH BI TU CHOI`: bạn chưa có quyền ghi. Kết quả đã nằm trong commit cục bộ; chạy `python orange/scripts/pack_member_results.py <ten>` để tạo file `member_results/<ten>_<ngày_giờ>.zip` và **gửi file zip cho M1** (qua chat/Drive).
- **Đây là thao tác git duy nhất bạn được làm** (ngoài `clone`, `checkout feature/tasr`, `fetch`, `show`).

## 13. Khi có sự cố

| Tình huống | Làm gì |
|---|---|
| Máy ngủ/tắt giữa chừng | Xem lệnh nào đã có file `setA-XX-wp-P<P>-cg-pc-lns.csv`. Chạy lại **chỉ các lệnh chưa có file** (và lệnh đang dở). Báo nhóm. |
| Julia hết bộ nhớ hoặc bị đóng | Đóng ứng dụng, chạy lại **lệnh dở** (một lần). Báo nhóm. |
| Lệnh báo thiếu bộ nhớ hoặc bỏ qua instance | Kiểm tra RAM trống, đóng ứng dụng. Nếu vẫn thiếu: báo nhóm để chia lại cho máy khác. |
| `check` khác `ok`, `ERROR` hoặc status lạ | **Giữ nguyên file**, đẩy kết quả (bước 10) và báo nhóm kèm log; không tự chạy lại. |
| `publish_member_results.py` từ chối vì file bị sửa | Hoàn tác thay đổi của bạn (`git checkout -- <file>` **chỉ cho file bạn lỡ sửa**), chạy lại. |
| Không chắc điều gì | **Dừng** và hỏi nhóm; đừng tự đoán hay thử nhiều lần. |

## 14. Dành cho coding agent

Nếu bạn là coding agent và người dùng nói họ là M2 hoặc M3:
1. **Đọc và làm theo đúng file này, từng bước, theo thứ tự.** Nếu người dùng chưa nói vai trò, hỏi: "Bạn là M2 hay M3?".
2. Chi tiết bổ sung và các quy tắc nghiêm ngặt dành cho agent: `project/AGENT_BRIEFS/00_NGU_CANH_CHUNG.md`, và khối PROMPT trong `project/AGENT_BRIEFS/M2_BRIEF.md` hoặc `M3_BRIEF.md`.
3. **Cấm:** sửa/xóa/đổi tên file được theo dõi trong git; dùng git ngoài các lệnh `clone`, `checkout feature/tasr`, `fetch`, `show` và lệnh `python orange/scripts/publish_member_results.py <ten>`; đẩy lên `main` hoặc `feature/tasr`; dùng `--force`; chạy hai tiến trình Julia nặng cùng lúc; chạy lại lệnh đã chạy xong; thay đổi cài đặt hệ thống (ngoài việc khởi chạy `keep_awake.ps1`).
4. Lệnh dài (khoảng 1 giờ mỗi lần) **phải chạy nền** với output ghi ra file; kiểm tra mỗi 20–30 phút; không busy-wait.
5. **Dừng và hỏi người dùng** khi: thiếu RAM, Julia lỗi, `check` khác `ok`, status lạ, trùng seed, máy ngủ, hoặc bất cứ điều gì không có trong tài liệu này. Báo cáo trung thực, kể cả thất bại hay kết quả một phần; **không bao giờ** sửa hay bịa số liệu.
6. Khi xong, viết **báo cáo cuối** gồm: vai trò; máy (CPU/RAM/OS từ `environment-<ten>.txt`); với mỗi lệnh: lệnh đã chạy, đường dẫn CSV, trạng thái, MLU và `check`, giờ bắt đầu và kết thúc, thời gian (cột `solve_time`), sự cố (máy ngủ, thiếu RAM, chạy lại); kết quả `publish_member_results.py` (hoặc đường dẫn zip); và điều người dùng nên kiểm tra lại.

## 15. Bạn đã xong khi

| Vai trò | Hoàn thành khi |
|---|---|
| **M2** | đủ 6 file `setA-06/09/11/12-wp-P2-cg-pc-lns.csv` và `setA-10/13-wp-P1-cg-pc-lns.csv`, mỗi file một dòng với `check` bắt đầu bằng `ok`; có `environment-m2.txt`; đã chạy `publish_member_results.py m2` thành công (hoặc đã gửi zip) |
| **M3** | đủ 4 file `setA-18/14/15-wp-P2-cg-pc-lns.csv` và `setA-14-wp-P1-cg-pc-lns.csv`, mỗi file một dòng với `check` bắt đầu bằng `ok`; có `environment-m3.txt`; đã chạy `publish_member_results.py m3` thành công (hoặc đã gửi zip) |

Cuối cùng nhắn nhóm: "M2/M3 xong, đã đẩy lên `results/m2` (hoặc `results/m3`)". M1 sẽ gộp, kiểm chứng và cập nhật bảng kết quả.

## 16. Tài liệu tham khảo trong repo

- `project/DE_XUAT_CAI_TIEN_TOI_UU.md` — lý do chọn các instance của M2/M3 và cách đánh giá kết quả.
- `project/PHAN_TICH_YEU_CAU_VA_PHAN_VIEC.md` — yêu cầu của thầy và các gói việc còn lại.
- `project/AGENT_BRIEFS/` — các bản giao việc chi tiết cho coding agent.
- `orange/README.md` — mã nguồn, cách chạy, các quyết định thiết kế.
- `orange/results/README_KET_QUA.md` và `orange/results/RUN_JOURNAL.md` — cách đọc kết quả và nhật ký các lần chạy.
