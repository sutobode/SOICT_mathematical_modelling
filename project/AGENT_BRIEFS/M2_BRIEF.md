# Giao việc cho coding agent: thành viên M2

> Sao chép **toàn bộ khối PROMPT bên dưới** và dán vào coding agent (mở agent tại thư mục gốc của dự án đã giải nén). Đọc trước `00_NGU_CANH_CHUNG.md`.

## PROMPT

```text
You are a coding agent assisting team member M2 of a university project. Your ONLY job is to run the optimisation experiments assigned below, verify them and package the results. You must NOT modify code.

FIRST read, in this order: HUONG_DAN_M2_M3_FINAL.md (the step-by-step guide; it is authoritative; START_HERE.md is the longer reference), project/AGENT_BRIEFS/00_NGU_CANH_CHUNG.md (rules and context) and project/HUONG_DAN_CHAY_SONG_SONG.md (sections 1-9). Obey every rule. In particular: never modify tracked files; use git ONLY for the commands allowed in START_HERE.md section 14 (clone, checkout feature/tasr, fetch, show) and for the single command `python orange/scripts/publish_member_results.py <name>`; run at most ONE heavy Julia process at a time; run long commands in the background with output redirected; never re-run a range whose CSV already exists; stop and ask the human when anything unexpected happens.

YOUR ASSIGNMENT (member M2) is the numbered TASKS below, in this order. The coordinator (M1) runs the remaining setA-04 and setA-05 runs; do NOT run those. Nobody else runs your instances, so do not change the instances, commands or order. Each task runs ONCE (the goal is a lower MLU, not an average). Rationale: project/DE_XUAT_CAI_TIEN_TOI_UU.md.

STEP 1 - Preflight. Run: python orange/scripts/preflight.py . Show me the output. If any REQUIRED item is missing (Julia 1.13.x, data, scripts), help install it (Julia: `juliaup add 1.13.1` then `juliaup default 1.13.1`) and re-run. Report the free RAM; stop and ask me if free RAM is below the requirement of your first task.

STEP 2 - Install and test. Run `julia --project=orange -e "using Pkg; Pkg.instantiate()"`, then `julia --project=orange orange/test/runtests.jl` (a few minutes, foreground is fine here). It must finish with no Fail/Error lines; if not, stop and report.

STEP 3 - Record the environment (mandatory, for traceability). Create orange/results/environment-m2.txt containing the output of `julia --project=orange -e "using InteractiveUtils; versioninfo(); using Pkg; Pkg.status()"` followed by the CPU model, total RAM in GB and OS name.

STEP 4 - Keep the machine awake. On Windows start, in the background, `powershell -NoProfile -ExecutionPolicy Bypass -File orange/scripts/keep_awake.ps1`. On other systems ask me to confirm that sleep is disabled. Ask me to confirm that the laptop is plugged in and the lid will stay open.

STEP 5 - Smoke test (about 1 minute). With JULIA_NUM_THREADS=1 run in the foreground: `julia --project=orange orange/scripts/run_experiments.jl 2 60 1 1 pc 1 1 -smoke` and then `python orange/scripts/check_range.py orange/results/setA-01-P2-pc-smoke.csv 1 1`. It must print COMPLETE. Otherwise stop and report.

STEP 6 - The assigned runs, strictly in this order, one at a time (details below). After each command finishes (the CSV exists and the process has exited) run the check command shown and record its output. Poll the running job at most every 20-30 minutes (process alive? CSV rows? free RAM?), without busy-waiting.

  TASK 1: setA-06, P=2.
     Command: julia --project=orange orange/scripts/run_wp.jl 2 3600 6 6 1500000 cg pc lns 900   (log -> orange/results/log-opt-P2-06.txt)
     Check:   python -c "import csv,sys; [print(r['instance'],r['P'],r['status'],r['mlu'],r['check']) for r in csv.DictReader(open(sys.argv[1]))]" orange/results/setA-06-wp-P2-cg-pc-lns.csv   (expect one row whose check starts with ok)
  TASK 2: setA-09, P=2.
     Command: julia --project=orange orange/scripts/run_wp.jl 2 3600 9 9 1500000 cg pc lns 900   (log -> orange/results/log-opt-P2-09.txt)
     Check:   python -c "import csv,sys; [print(r['instance'],r['P'],r['status'],r['mlu'],r['check']) for r in csv.DictReader(open(sys.argv[1]))]" orange/results/setA-09-wp-P2-cg-pc-lns.csv   (expect one row whose check starts with ok)
  TASK 3: setA-11, P=2.
     Command: julia --project=orange orange/scripts/run_wp.jl 2 3600 11 11 1500000 cg pc lns 900   (log -> orange/results/log-opt-P2-11.txt)
     Check:   python -c "import csv,sys; [print(r['instance'],r['P'],r['status'],r['mlu'],r['check']) for r in csv.DictReader(open(sys.argv[1]))]" orange/results/setA-11-wp-P2-cg-pc-lns.csv   (expect one row whose check starts with ok)
  TASK 4: setA-12, P=2.
     Command: julia --project=orange orange/scripts/run_wp.jl 2 3600 12 12 1500000 cg pc lns 900   (log -> orange/results/log-opt-P2-12.txt)
     Check:   python -c "import csv,sys; [print(r['instance'],r['P'],r['status'],r['mlu'],r['check']) for r in csv.DictReader(open(sys.argv[1]))]" orange/results/setA-12-wp-P2-cg-pc-lns.csv   (expect one row whose check starts with ok)
  TASK 5: setA-10, P=1.
     Command: julia --project=orange orange/scripts/run_wp.jl 1 1800 10 10 1500000 cg pc lns 900   (log -> orange/results/log-opt-P1-10.txt)
     Check:   python -c "import csv,sys; [print(r['instance'],r['P'],r['status'],r['mlu'],r['check']) for r in csv.DictReader(open(sys.argv[1]))]" orange/results/setA-10-wp-P1-cg-pc-lns.csv   (expect one row whose check starts with ok)
  TASK 6: setA-13, P=1.
     Command: julia --project=orange orange/scripts/run_wp.jl 1 1800 13 13 1500000 cg pc lns 900   (log -> orange/results/log-opt-P1-13.txt)
     Check:   python -c "import csv,sys; [print(r['instance'],r['P'],r['status'],r['mlu'],r['check']) for r in csv.DictReader(open(sys.argv[1]))]" orange/results/setA-13-wp-P1-cg-pc-lns.csv   (expect one row whose check starts with ok)
  If free RAM drops below about 3 GB or a command fails, STOP and report to me; do not retry blindly. A result whose MLU is not lower than the value in orange/results/best_known.csv is still kept (evidence); never edit best_known.csv or the tables.

STEP 7 - Publish. After EACH finished range (and when you finish, when I ask, or if you must stop early) run `python orange/scripts/publish_member_results.py m2 --dry-run`, show me the list, then `python orange/scripts/publish_member_results.py m2`; it creates the branch results/m2 and pushes ONLY result files (never main or feature/tasr, never --force). If the push is refused (no write access), run `python orange/scripts/pack_member_results.py m2` instead and tell me the path of the zip in member_results/ so that I can send it to the coordinator.

STEP 8 - Final report to me (to forward to the coordinator), in exactly this format, with no omissions:
  Member: M2
  Machine: CPU / RAM / OS (from environment-m2.txt)
  For each assigned task: command used, CSV path, the printed check row (status, mlu, check), start and end time, duration per run (solve_time column), any incident (machine sleep, low RAM, crash, restart, anything unusual)
  Publish result (branch results/m2) or zip path
  Anything I should double-check.
Be honest: report failures and partial results exactly as they are.
```

## Tiêu chí hoàn thành
- Đủ các file `setA-06/09/11/12-wp-P2-cg-pc-lns.csv` and `setA-10/13-wp-P1-cg-pc-lns.csv`, mỗi file một dòng có `check` bắt đầu bằng `ok`; có `environment-m2.txt`; đã chạy `publish_member_results.py m2` thành công (hoặc đã gửi zip cho M1).

## Nếu agent hỏi hoặc dừng
- **Thiếu RAM:** đóng trình duyệt và ứng dụng nặng, mở Task Manager xem RAM trống, rồi bảo agent chạy lại `preflight.py`.
- **Máy ngủ hoặc tắt giữa chừng:** bảo agent làm theo mục 6 của `HUONG_DAN_CHAY_SONG_SONG.md` (chạy lại **chỉ các lệnh chưa có file kết quả**); **không** chạy lại lệnh đã xong.
- **Agent định sửa code hoặc dùng git:** dừng agent và nhắc "Không được sửa file được theo dõi và không dùng git".
- **Muốn gửi kết quả sớm:** bảo agent chạy bước 7 (đóng gói) ngay; việc đóng gói không làm gián đoạn lần chạy đang diễn ra.
