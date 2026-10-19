# Hồ sơ truy vết kết quả thực nghiệm

Tạo lúc: 2026-10-19 21:34:58

## Phiên bản mã nguồn

- Repository: `https://github.com/sutobode/SOICT_mathematical_modelling.git`
- Nhánh: `feature/tasr`; commit hiện tại: `53ca7d4` (feat: fast pipeline (no MILP, CG on first period, LNS) for large t=0,1 instances)
- Commit chưa lưu (thay đổi chưa commit trong `orange/src`): 0 file
- SHA-256 của `orange/Manifest.toml` (khóa phiên bản thư viện Julia): `268873ad2c6ebc345270b30f982354b34d73580d0ce29ed47724c5e22ff8b8b2`

## Môi trường

```
Julia Version 1.13.1
Commit 96ca370cf0 (2026-09-25 19:34 UTC)
Build Info:
  Official https://julialang.org release
Platform Info:
  OS: Windows (x86_64-w64-mingw32)
  CPU: 16 × 12th Gen Intel(R) Core(TM) i7-1270P
  WORD_SIZE: 64
  LLVM: libLLVM-20.1.8 (ORCJIT, alderlake)
  GC: Built with stock GC
Threads: 1 default, 1 interactive, 1 GC (on 16 virtual cores)
Project Orange v0.1.0
Status `C:\Users\X1\Project\SOICT_mathematical_modelling\orange\Project.toml`
  [86223c79] Graphs v1.15.0
```

## Tham số cố định của mọi lần chạy

- Solver: HiGHS qua JuMP, **1 luồng** (`threads=1`), `mip_rel_gap = 1e-6`, `random_seed = số thứ tự lần chạy` (mô hình theo cung).
- Hàm mục tiêu: min z + ε·Σx với ε = 1e-7/|D| (z là MLU); gap báo cáo = 1 − bound/obj trên cùng hàm mục tiêu.
- Giới hạn thời gian: 1800 s cho chỉ t=0 (bước 6), 3600 s cho t=0,1 (bước 9). CPU time = `solve_time` của `optimize!` (thời gian thực, 1 luồng).
- Số lần chạy: 10 nếu lần đầu giải trong 120 s, nếu không 3 lần (cột `run` trong CSV).
- Mô hình theo cung bị bỏ qua (`SKIPPED_TOO_LARGE`) khi |D|·P·n·(n−1) > 3·10⁶ biến; khi đó dùng mô hình waypoint (bài toán hạn chế một waypoint).
- Dung sai hòa khoảng cách khi tính r: 1e-9 tương đối. Khởi tạo MILP bằng nghiệm heuristic (thời gian ghi riêng, không tính vào CPU time).

## Các lệnh đã chạy và file kết quả tương ứng

| Mục đích | Lệnh | File kết quả |
|---|---|---|
| Bảng chính thức t=0 (bước 6), mô hình theo cung, r theo calculating_r.pdf | `julia --project=orange orange/scripts/run_experiments.jl 1 1800 1 20 pc   (instance 01–03; 04–20 chạy lại bằng `... 1 1800 4 20 pc`)` | setA-XX-P1-pc.csv, -srpaths.json, -loads.csv, log-pc-P1*.txt |
| Bảng chính thức t=0,1 (bước 9), mô hình theo cung, r theo calculating_r.pdf | `julia --project=orange orange/scripts/run_experiments.jl 2 3600 1 20 pc` | setA-XX-P2-pc.csv, ..., log-pc-P2.txt |
| Mô hình theo cung, r theo ECMP (kiểm chứng; kết quả trùng bảng chính thức) | `julia --project=orange orange/scripts/run_experiments.jl 1 1800  /  ... 2 3600 1 20 (một phần)` | setA-XX-P{1,2}.csv, log-P1.txt, log-P2.txt |
| Mô hình waypoint, ứng viên theo độ vòng (tối ưu một waypoint khi K = n-2) | `julia --project=orange orange/scripts/run_wp.jl 1 1800 1 13  /  ... 2 3600 1 13 (dừng sớm vì trùng với sinh cột)` | setA-XX-wp-P{1,2}.csv, log-wp-P{1,2}.txt |
| Mô hình waypoint + sinh cột (kết quả cho cả 20 instance) | `julia --project=orange orange/scripts/run_wp.jl 1 1800 1 20 1500000 cg  /  ... 2 3600 1 20 1500000 cg` | setA-XX-wp-P{1,2}-cg.csv, log-wp-cg-P{1,2}.txt |
| Sinh cột với r theo công thức của thầy (chỉ instance khác ECMP: 18 và 20; 01–09 chạy thử) | `julia --project=orange orange/scripts/run_wp.jl <P> <giây> 18 18 1500000 cg pc  (và 20)` | setA-XX-wp-P{1,2}-cg-pc.csv, log-wp-cg-pc-*.txt |
| Tinh chỉnh LNS cho instance còn gap lớn | `julia --project=orange orange/scripts/run_wp.jl 1 300 <i> <i> 1500000 cg ecmp lns  /  ... 2 300 <i> <i> 1500000 cg ecmp lns 900` | setA-XX-wp-P{1,2}-cg-lns.csv, log-wp-cg-lns-*.txt |
| So sánh r theo ECMP và theo công thức của thầy | `julia --project=orange orange/scripts/r_difference.jl` | r_difference.csv |
| Kiểm tra độc lập bằng Python | `python -I orange/scripts/verify_srpaths.py` | verification.csv |
| Tổng hợp | `julia orange/scripts/best_known.jl ; julia orange/scripts/official_tables.jl` | best_known.csv, table_official_P{1,2}.md/.csv |

## Cách kiểm tra lại một kết quả

1. **Dữ liệu đầu vào:** so SHA-256 của `project/setA/*.json` với `MANIFEST_INPUTS.csv`.
2. **File kết quả:** so SHA-256 với `MANIFEST.csv`; cột `code_commit` là commit mã nguồn gần nhất trước khi file được ghi (`git show <commit>`).
3. **Tính lại độc lập:** `python -I orange/scripts/verify_srpaths.py setA-04` đọc `*-srpaths.json` và tính lại ECMP, tải, MLU, ngân sách, maxSeg từ dữ liệu gốc (cài đặt riêng bằng Python); kết quả trong `verification.csv`.
4. **Chạy lại một instance:** ví dụ `julia --project=orange orange/scripts/run_experiments.jl 1 1800 5 5 pc` (setA-05, t=0, r của thầy).
5. **Kiểm thử mã nguồn:** `julia --project=orange orange/test/runtests.jl` (mô hình khớp vét cạn, r khớp Bảng 2 của đề).

Lưu ý: một lần chạy dài bị gián đoạn bởi việc máy ngủ (Windows Modern Standby 18:40–19:10 ngày 19/10, xem `Kernel-Power` trong nhật ký hệ thống) có `solve_time` tính cả thời gian ngủ; các lần chạy này, nếu có, được đánh dấu trong báo cáo kết quả.
