# Ngữ cảnh chung cho mọi coding agent (đọc trước tiên)

> Dành cho thành viên nhóm (đọc phần "Cách dùng") và cho **coding agent** (đọc toàn bộ). Phần còn lại viết bằng tiếng Anh để agent hiểu chính xác.

## Cách dùng (cho thành viên)

1. Lấy mã nguồn bằng link git (xem `START_HERE.md`, bước 1: `git clone ...` rồi `git checkout feature/tasr`). **Mở chính thư mục đó** bằng coding agent (Claude Code, Cursor, Codex, ...). Chỉ cần nói với agent: "Tôi là M2 (hoặc M3). Hãy đọc START_HERE.md và làm đúng phần việc của tôi."
2. Mở file brief của bạn: `project/AGENT_BRIEFS/M2_BRIEF.md` (hoặc `M3_BRIEF.md`). Sao chép **toàn bộ khối "PROMPT"** và dán vào agent làm lệnh đầu tiên.
3. Agent sẽ tự: kiểm tra máy, cài thư viện, chạy kiểm thử, ghi môi trường, chạy các lệnh được giao ở chế độ nền, kiểm tra kết quả và gói kết quả để gửi lại. Bạn chỉ cần: giữ máy thức (cắm sạc, không gập nắp), đóng ứng dụng nặng, trả lời khi agent hỏi, và gửi file zip kết quả cho người điều phối (M1).
4. **Agent bị cấm sửa mã nguồn.** Agent chỉ được dùng git cho các lệnh liệt kê ở quy tắc 2; việc đẩy kết quả lên nhánh riêng `results/<tên>` chỉ làm qua `publish_member_results.py`. Nếu thấy agent định làm khác, dừng lại.

## Context for the agent (English)

**Project.** SOICT mathematical-modelling course project (team of 3, "Orange T-ASR", ROADEF/EURO 2026 challenge). The repo contains a Julia package `orange/` (JuMP + HiGHS) that solves *T-Adaptive Segment Routing*: route each demand through at most a few waypoints so that the maximum link utilisation (MLU) is minimised, over time periods t=0 (nominal) and t=1 (one link down, with a budget on routing changes). Instances: `project/setA/setA-01..20-{net,tm,scenario}.json`. The official result tables ask, for each instance, the average over **10 runs** (seeds 1..10) of CPU time, gap and B&B nodes, with a time limit of 1800 s (t=0 only) or 3600 s (t=0,1).

**What the team still needs.** The remaining *runs* of the arc-based MILP (the teacher's model) for slow rows. Each run is independent (seed = run number), so runs are split across three machines in **disjoint seed ranges**. Each range writes its own CSV (`orange/results/setA-XX-P{P}-pc-r<a>-<b>.csv`); the coordinator merges all files and checks for overlaps. See `project/HUONG_DAN_CHAY_SONG_SONG.md` (sections 1–9) for the assignment.

**Key files.**
- `orange/scripts/run_experiments.jl` — runner. Usage: `julia --project=orange orange/scripts/run_experiments.jl <P> <time_limit_s> <first_instance> <last_instance> pc <first_seed> <last_seed> <suffix> [mem_budget_GB]` (`P=2` means periods 0 and 1; `pc` = split coefficients from the teacher's PDF; the suffix names the output file, e.g. `-r5-7`).
- `orange/scripts/preflight.py` — checks Julia/RAM/data. `orange/scripts/check_range.py` — validates one range CSV. `orange/scripts/pack_member_results.py` — packs your results for the coordinator.
- Outputs: `orange/results/*.csv`, `orange/results/solverlogs/*.log` (verbatim HiGHS logs per run), `orange/results/log-*.txt` (console logs).

## Rules for every agent (non-negotiable)

1. **Never modify, delete or rename any tracked file** (everything under `orange/src`, `orange/scripts`, `orange/test`, `orange/Project.toml`, `orange/Manifest.toml`, `project/`, `report/`). Only create new files under `orange/results/` and `member_results/`.
2. **Git is restricted.** Allowed only: `git clone`, `git checkout feature/tasr`, `git fetch`, `git show`, `git log`, `git status`, and the single command `python orange/scripts/publish_member_results.py <name>` (it creates branch `results/<name>` and pushes only result files). **Never** run `git commit`, `git add`, `git push` yourself, `git reset`, any `--force`, never push to `main` or `feature/tasr`, never change git config. If the push is refused, return the results as a zip (`python orange/scripts/pack_member_results.py <name>`).
3. **At most ONE heavy Julia process at a time.** Peak RAM: setA-04 (t=0,1) ≈ 8 GB, setA-05 (t=0,1) ≈ 11–14 GB. Starting a second one exhausts RAM (this already killed runs on the coordinator's machine).
4. **Never re-run a range whose CSV already exists**: the command overwrites it. To resume an interrupted range, run only the missing seeds with a **new suffix** (e.g. if `-r5-7` finished seed 5, run seeds `6 7` with suffix `-r6-7`).
5. **Long jobs run in the background** with stdout/stderr redirected to a log file (one run ≈ 1 hour; a range = hours). Use your tool's background mode (Claude Code: `run_in_background`; Linux/macOS: `nohup ... &`; Windows PowerShell: `Start-Process`). **Never** run them in the foreground with a timeout. Poll at most every 20–30 minutes; do not busy-wait.
6. Set `JULIA_NUM_THREADS=1` and `OPENBLAS_NUM_THREADS=1` before every Julia command.
7. Do not run other heavy programs, do not change power or system settings (other than launching `orange/scripts/keep_awake.ps1` on Windows to prevent sleep).
8. If anything unexpected happens (low RAM, Julia crash, `check` ≠ `ok`, a status other than `Optimal`/`Not Optimal`, overlapping seeds, the machine slept) **stop and report to the human**; do not improvise or retry blindly.
9. Report honestly: include failures, partial ranges and incidents. Never fabricate or edit result numbers.

## Platform notes

- **Windows (PowerShell), background launch template:**
  ```powershell
  $env:JULIA_NUM_THREADS="1"; $env:OPENBLAS_NUM_THREADS="1"
  Start-Process -NoNewWindow -FilePath julia -ArgumentList '--project=orange','orange/scripts/run_experiments.jl','2','3600','4','4','pc','5','7','-r5-7' `
    -RedirectStandardOutput orange/results/log-pc-P2-04-r5-7.txt -RedirectStandardError orange/results/log-pc-P2-04-r5-7.err
  ```
- **Linux/macOS:**
  ```bash
  export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
  nohup julia --project=orange orange/scripts/run_experiments.jl 2 3600 4 4 pc 5 7 -r5-7 > orange/results/log-pc-P2-04-r5-7.txt 2>&1 &
  ```
- Check that the process is alive: Windows `Get-Process julia | Select Id,CPU,WorkingSet64`; Linux/macOS `ps aux | grep julia`.
- The CSV for a range appears (with its first row) only after the **first run of that range finishes** (≈ 1 hour for setA-04 t=0,1); an empty or missing CSV during the first hour is normal.
