# Giao việc cho coding agent: thành viên M2

> Sao chép **toàn bộ khối PROMPT bên dưới** và dán vào coding agent (mở agent tại thư mục gốc của dự án đã giải nén). Đọc trước `00_NGU_CANH_CHUNG.md`.

## PROMPT

```text
You are a coding agent assisting team member M2 of a university project. Your ONLY job is to run long numerical experiments, verify them and package the results. You must NOT modify code.

FIRST read, in this order: project/AGENT_BRIEFS/00_NGU_CANH_CHUNG.md (rules and context) and project/HUONG_DAN_CHAY_SONG_SONG.md (sections 1-9). Obey every rule in 00_NGU_CANH_CHUNG.md. In particular: never modify tracked files, never use git, run at most ONE heavy Julia process at a time, run long commands in the background with output redirected, never re-run a range whose CSV already exists, stop and ask the human when anything unexpected happens.

YOUR ASSIGNMENT (member M2) is TASK A, TASK B, TASK C below, in this order. Nobody else runs these seed ranges, so do not change the ranges, seeds or suffixes.

STEP 1 - Preflight. Run: python orange/scripts/preflight.py . Show me the output. If any REQUIRED item is missing (Julia 1.13.x, data, scripts), help install it (Julia: `juliaup add 1.13.1` then `juliaup default 1.13.1`) and re-run. Report the free RAM; stop and ask me if free RAM is below the requirement of your first task.

STEP 2 - Install and test. Run `julia --project=orange -e "using Pkg; Pkg.instantiate()"`, then `julia --project=orange orange/test/runtests.jl` (a few minutes, foreground is fine here). It must finish with no Fail/Error lines; if not, stop and report.

STEP 3 - Record the environment (mandatory, for traceability). Create orange/results/environment-m2.txt containing the output of `julia --project=orange -e "using InteractiveUtils; versioninfo(); using Pkg; Pkg.status()"` followed by the CPU model, total RAM in GB and OS name.

STEP 4 - Keep the machine awake. On Windows start, in the background, `powershell -NoProfile -ExecutionPolicy Bypass -File orange/scripts/keep_awake.ps1`. On other systems ask me to confirm that sleep is disabled. Ask me to confirm that the laptop is plugged in and the lid will stay open.

STEP 5 - Smoke test (about 1 minute). With JULIA_NUM_THREADS=1 run in the foreground: `julia --project=orange orange/scripts/run_experiments.jl 2 60 1 1 pc 1 1 -smoke` and then `python orange/scripts/check_range.py orange/results/setA-01-P2-pc-smoke.csv 1 1`. It must print COMPLETE. Otherwise stop and report.

STEP 6 - The assigned runs, strictly in this order, one at a time (details below). After each command finishes (the CSV exists and the process has exited) run the check command shown and record its output. Poll the running job at most every 20-30 minutes (process alive? CSV rows? free RAM?), without busy-waiting.

  TASK A (pilot, about 65 minutes): setA-05, periods 0 and 1, seed 1 only.
     Command: julia --project=orange orange/scripts/run_experiments.jl 2 3600 5 5 pc 1 1 -r1-1   (stdout/stderr -> orange/results/log-pc-P2-05-r1-1.txt)
     Check:   python orange/scripts/check_range.py orange/results/setA-05-P2-pc-r1-1.csv 1 1
     If check_range prints COMPLETE (exit code 0): the pilot succeeded, continue. If the status is SKIPPED_LOW_MEMORY or ERROR, or the machine ran out of memory: STOP setA-05 (skip Task C), tell me clearly, and continue with Task B only. Tell me the pilot result as soon as you have it so that I can forward it to the coordinator.
     If the status is SKIPPED_LOW_MEMORY, do NOT retry on your own: ask me; I will check Task Manager and, if at least 14 GB of RAM is really free, tell you to add the last argument 14 (memory budget in GB) and re-run the same command (same suffix).
  TASK B (about 3.2 hours): setA-04, periods 0 and 1, seeds 5 to 7.
     Command: julia --project=orange orange/scripts/run_experiments.jl 2 3600 4 4 pc 5 7 -r5-7   (log -> orange/results/log-pc-P2-04-r5-7.txt)
     Check:   python orange/scripts/check_range.py orange/results/setA-04-P2-pc-r5-7.csv 5 7
  TASK C (about 4.4 hours, ONLY if the pilot succeeded): setA-05, periods 0 and 1, seeds 2 to 5.
     Command: julia --project=orange orange/scripts/run_experiments.jl 2 3600 5 5 pc 2 5 -r2-5   (log -> orange/results/log-pc-P2-05-r2-5.txt)
     Check:   python orange/scripts/check_range.py orange/results/setA-05-P2-pc-r2-5.csv 2 5

STEP 7 - Package. When you finish (or when I ask, or if you must stop early), run `python orange/scripts/pack_member_results.py m2` and tell me the path of the produced zip in member_results/.

STEP 8 - Final report to me (to forward to the coordinator), in exactly this format, with no omissions:
  Member: M2
  Machine: CPU / RAM / OS (from environment-m2.txt)
  For each assigned range: command used, CSV path, output of check_range.py, start and end time, duration per run (solve_time column), any incident (machine sleep, low RAM, crash, restart, anything unusual)
  Zip path
  Anything I should double-check.
Be honest: report failures and partial results exactly as they are.
```

## Tiêu chí hoàn thành
- `setA-05-P2-pc-r1-1.csv` (1 dòng, đã báo kết quả pilot), `setA-04-P2-pc-r5-7.csv` (3 dòng), `setA-05-P2-pc-r2-5.csv` (4 dòng, nếu pilot ổn); `check_range.py` báo COMPLETE cho mỗi khoảng; có `environment-m2.txt`; đã có file zip trong `member_results/` và đã gửi cho M1.

## Nếu agent hỏi hoặc dừng
- **Thiếu RAM:** đóng trình duyệt và ứng dụng nặng, mở Task Manager xem RAM trống, rồi bảo agent chạy lại `preflight.py`.
- **Máy ngủ hoặc tắt giữa chừng:** bảo agent làm theo mục 6 của `HUONG_DAN_CHAY_SONG_SONG.md` (chạy phần còn thiếu bằng khoảng con và hậu tố mới); **không** chạy lại khoảng đã có CSV.
- **Agent định sửa code hoặc dùng git:** dừng agent và nhắc "Không được sửa file được theo dõi và không dùng git".
- **Muốn gửi kết quả sớm:** bảo agent chạy bước 7 (đóng gói) ngay; việc đóng gói không làm gián đoạn lần chạy đang diễn ra.
