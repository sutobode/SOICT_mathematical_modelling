# Prompt sẵn cho coding agent của M2 và M3

**Cách dùng (30 giây):**
1. Mở coding agent (Claude Code, Cursor, Codex, Copilot Agent, ...) ở **một thư mục trống bất kỳ** trên máy của bạn (agent sẽ tự clone repo).
2. Sao chép **đúng khối prompt của bạn** (M2 hoặc M3) bên dưới, dán vào agent, gửi.
3. Trả lời các câu agent hỏi (xác nhận cắm sạc, tắt ngủ, RAM, quyền ghi GitHub...). Phần còn lại agent tự làm.

Hướng dẫn đầy đủ để người đọc: `HUONG_DAN_M2_M3_FINAL.md` (nếu khác với prompt này, file đó đúng). Máy cần: RAM ≥ 16 GB (trống ≥ 8 GB), cắm sạc, không gập nắp.

---

## PROMPT CHO M2

```text
You are a coding agent assisting team member M2 of a university project (T-Adaptive Segment Routing, Julia + JuMP + HiGHS). Your ONLY job is to run the optimisation experiments assigned below on this machine, verify them, and publish the results. You must NOT modify any code or document.

STEP 0 - Get the repository. If the current directory is not already the repository, run:
  git clone https://github.com/sutobode/SOICT_mathematical_modelling.git soict
  cd soict
Stay on the default branch `main` (it is the primary branch and has everything you need; do NOT check out any other branch yet). Run `git branch --show-current` (must print main) and `git log -1 --oneline` and remember the output. Never commit or push to `main`. If `git clone` is denied, tell me and ask me for the zip file `member_kit_*.zip`.

STEP 1 - Read. Read HUONG_DAN_M2_M3_FINAL.md in the repository root completely. It is authoritative; follow it literally, step by step. If anything in this prompt differs from it, the file wins. I am M2.

STEP 2 - Setup, exactly as sections 2-3 of that file: machine requirements, git identity (set `git config user.name`/`user.email` to MY name if unset; ask me for it), Julia 1.13.1 (juliaup), Python 3, `python orange/scripts/preflight.py`, `julia --project=orange -e "using Pkg; Pkg.instantiate()"`, `julia --project=orange orange/test/runtests.jl` (must show no Fail/Error), create `orange/results/environment-m2.txt`, keep the machine awake (on Windows start orange/scripts/keep_awake.ps1 in a separate background process; ask me to confirm that the laptop is plugged in and sleep is disabled), and the 1-minute smoke test. STOP and report to me if any of these fails.

STEP 3 - Run my assignment, ONE command at a time, strictly in this order, each ONCE, in the background with output redirected to the log file shown, with JULIA_NUM_THREADS=1 and OPENBLAS_NUM_THREADS=1:
  1. julia --project=orange orange/scripts/run_wp.jl 2 3600 6 6 1500000 cg pc lns 900     (log: orange/results/log-opt-P2-06.txt)
  2. julia --project=orange orange/scripts/run_wp.jl 2 3600 9 9 1500000 cg pc lns 900     (log: orange/results/log-opt-P2-09.txt)
  3. julia --project=orange orange/scripts/run_wp.jl 2 3600 11 11 1500000 cg pc lns 900   (log: orange/results/log-opt-P2-11.txt)
  4. julia --project=orange orange/scripts/run_wp.jl 2 3600 12 12 1500000 cg pc lns 900   (log: orange/results/log-opt-P2-12.txt)
  5. julia --project=orange orange/scripts/run_wp.jl 1 1800 10 10 1500000 cg pc lns 900   (log: orange/results/log-opt-P1-10.txt)
  6. julia --project=orange orange/scripts/run_wp.jl 1 1800 13 13 1500000 cg pc lns 900   (log: orange/results/log-opt-P1-13.txt)
Each command can take from a few minutes up to about 1.5 hours. Poll at most every 20-30 minutes (process alive, free RAM); never busy-wait; never start a second Julia process while one is running. When a command has exited, check its result file (instance 9, P=2 shown as an example; adapt the path):
  python -c "import csv,sys; [print(r['instance'],r['P'],r['status'],r['mlu'],r['check']) for r in csv.DictReader(open(sys.argv[1]))]" orange/results/setA-09-wp-P2-cg-pc-lns.csv
Expected: exactly one row whose last column (check) starts with "ok". A result whose MLU is not lower than the value in orange/results/best_known.csv is still kept. Never edit best_known.csv, tables or any tracked file.

STEP 4 - Publish after EACH finished command (and when you must stop early): `python orange/scripts/publish_member_results.py m2 --dry-run`, show me the list, then `python orange/scripts/publish_member_results.py m2`. It creates and pushes the branch results/m2 only. After the first publish this repository stays on branch results/m2: that is normal. If the push is rejected, run `python orange/scripts/pack_member_results.py m2` and tell me to send the produced zip in member_results/ to the coordinator.

HARD RULES: never modify, delete or rename any tracked file; the only git commands allowed are clone, fetch, pull (only to get a newer `main`), show, log, status and publish_member_results.py; never push to main or to any branch other than results/<name>; never use --force; never re-run a command that already finished (it overwrites its result); only ONE Julia process at a time; do not change system settings except launching keep_awake.ps1; do not run other heavy programs.
STOP and ask me if: free RAM drops below about 3 GB, Julia crashes or is out of memory, a check value is not "ok", a status looks unusual, the machine slept, a file listed by the publish dry-run looks wrong, or anything happens that this prompt or HUONG_DAN_M2_M3_FINAL.md does not cover. After a sleep/crash, re-run ONLY the commands that have no result file yet (plus the one that was interrupted) after telling me.
If I run out of time, publish what is finished and report which commands are done and which are not.

STEP 5 - Final report to me (in Vietnamese, to forward to the coordinator), exactly in this format, with no omissions and no invented numbers:
  Thanh vien: M2
  May: CPU / RAM / OS (from environment-m2.txt)
  Commit da clone: <git log -1 --oneline>
  Moi lenh: lenh da chay, duong dan CSV, dong check (status, mlu, check), gio bat dau va ket thuc, thoi gian (cot solve_time), su co (may ngu, thieu RAM, chay lai...)
  Ket qua publish (nhanh results/m2) hoac duong dan zip
  Dieu can kiem tra lai: ...
Be honest: report failures and partial results exactly as they are.
```

---

## PROMPT CHO M3

```text
You are a coding agent assisting team member M3 of a university project (T-Adaptive Segment Routing, Julia + JuMP + HiGHS). Your ONLY job is to run the optimisation experiments assigned below on this machine, verify them, and publish the results. You must NOT modify any code or document.

STEP 0 - Get the repository. If the current directory is not already the repository, run:
  git clone https://github.com/sutobode/SOICT_mathematical_modelling.git soict
  cd soict
Stay on the default branch `main` (it is the primary branch and has everything you need; do NOT check out any other branch yet). Run `git branch --show-current` (must print main) and `git log -1 --oneline` and remember the output. Never commit or push to `main`. If `git clone` is denied, tell me and ask me for the zip file `member_kit_*.zip`.

STEP 1 - Read. Read HUONG_DAN_M2_M3_FINAL.md in the repository root completely. It is authoritative; follow it literally, step by step. If anything in this prompt differs from it, the file wins. I am M3.

STEP 2 - Setup, exactly as sections 2-3 of that file: machine requirements, git identity (set `git config user.name`/`user.email` to MY name if unset; ask me for it), Julia 1.13.1 (juliaup), Python 3, `python orange/scripts/preflight.py`, `julia --project=orange -e "using Pkg; Pkg.instantiate()"`, `julia --project=orange orange/test/runtests.jl` (must show no Fail/Error), create `orange/results/environment-m3.txt`, keep the machine awake (on Windows start orange/scripts/keep_awake.ps1 in a separate background process; ask me to confirm that the laptop is plugged in and sleep is disabled), and the 1-minute smoke test. STOP and report to me if any of these fails.

STEP 3 - Run my assignment, ONE command at a time, strictly in this order, each ONCE, in the background with output redirected to the log file shown, with JULIA_NUM_THREADS=1 and OPENBLAS_NUM_THREADS=1:
  1. julia --project=orange orange/scripts/run_wp.jl 2 3600 18 18 1500000 cg pc lns 900   (log: orange/results/log-opt-P2-18.txt)
  2. julia --project=orange orange/scripts/run_wp.jl 2 3600 14 14 1500000 cg pc lns 900   (log: orange/results/log-opt-P2-14.txt)
  3. julia --project=orange orange/scripts/run_wp.jl 2 3600 15 15 1500000 cg pc lns 900   (log: orange/results/log-opt-P2-15.txt)
  4. julia --project=orange orange/scripts/run_wp.jl 1 1800 14 14 1500000 cg pc lns 900   (log: orange/results/log-opt-P1-14.txt)
  OPTIONAL 5 (only after 1-4 are done AND free RAM is at least 12 GB; ask me first):
     julia --project=orange orange/scripts/run_wp.jl 1 1800 19 19 1500000 cg pc lns 900   (log: orange/results/log-opt-P1-19.txt)
Each command can take from a few minutes up to about 1.5 hours. Poll at most every 20-30 minutes (process alive, free RAM); never busy-wait; never start a second Julia process while one is running. When a command has exited, check its result file (instance 18, P=2 shown as an example; adapt the path):
  python -c "import csv,sys; [print(r['instance'],r['P'],r['status'],r['mlu'],r['check']) for r in csv.DictReader(open(sys.argv[1]))]" orange/results/setA-18-wp-P2-cg-pc-lns.csv
Expected: exactly one row whose last column (check) starts with "ok". A result whose MLU is not lower than the value in orange/results/best_known.csv is still kept. Never edit best_known.csv, tables or any tracked file.

STEP 4 - Publish after EACH finished command (and when you must stop early): `python orange/scripts/publish_member_results.py m3 --dry-run`, show me the list, then `python orange/scripts/publish_member_results.py m3`. It creates and pushes the branch results/m3 only. After the first publish this repository stays on branch results/m3: that is normal. If the push is rejected, run `python orange/scripts/pack_member_results.py m3` and tell me to send the produced zip in member_results/ to the coordinator.

HARD RULES: never modify, delete or rename any tracked file; the only git commands allowed are clone, fetch, pull (only to get a newer `main`), show, log, status and publish_member_results.py; never push to main or to any branch other than results/<name>; never use --force; never re-run a command that already finished (it overwrites its result); only ONE Julia process at a time; do not change system settings except launching keep_awake.ps1; do not run other heavy programs.
STOP and ask me if: free RAM drops below about 3 GB, Julia crashes or is out of memory, a check value is not "ok", a status looks unusual, the machine slept, a file listed by the publish dry-run looks wrong, or anything happens that this prompt or HUONG_DAN_M2_M3_FINAL.md does not cover. After a sleep/crash, re-run ONLY the commands that have no result file yet (plus the one that was interrupted) after telling me.
If I run out of time, publish what is finished and report which commands are done and which are not.

STEP 5 - Final report to me (in Vietnamese, to forward to the coordinator), exactly in this format, with no omissions and no invented numbers:
  Thanh vien: M3
  May: CPU / RAM / OS (from environment-m3.txt)
  Commit da clone: <git log -1 --oneline>
  Moi lenh: lenh da chay, duong dan CSV, dong check (status, mlu, check), gio bat dau va ket thuc, thoi gian (cot solve_time), su co (may ngu, thieu RAM, chay lai...)
  Ket qua publish (nhanh results/m3) hoac duong dan zip
  Dieu can kiem tra lai: ...
Be honest: report failures and partial results exactly as they are.
```
