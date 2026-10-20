#!/bin/bash
# Chạy tiếp sau khi bật lại máy (M1). Làm tuần tự các lần chạy bù còn thiếu, mỗi lần MỘT tiến trình:
#   1) setA-04 t=0,1 seed 6        -> file -r6-6b
#   2) setA-05 t=0,1 seed 10       -> file -r10-10b   (cần RAM trống >= 12 GB: đóng trình duyệt và ứng dụng nặng)
#   3) setA-04 t=0   seed 4 (chạy lại, để có nghiệm kiểm chứng của 0,50105) -> file -r4-4v (không gộp vào bảng)
# Nhật ký: orange/results/resume_m1.log. Lần nào đã có dòng CSV hợp lệ thì bỏ qua.
# Cách chạy:   bash orange/scripts/resume_m1.sh
cd "$(dirname "$0")/../.." || exit 1
LOG=orange/results/resume_m1.log
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
say() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }
free_gb() { powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)" | tr -d '\r' | tr ',' '.'; }
wait_ram() { while python -c "import sys; sys.exit(0 if float('$(free_gb)') >= $1 else 1)"; [ $? -ne 0 ]; do say "cho RAM trong >= $1 GB (hien $(free_gb) GB)"; sleep 60; done; }
have_ok() { # have_ok <file> <run>: file có dòng của lần chạy này với check=ok?
  python -I - "$1" "$2" <<'PY'
import csv, os, sys
f, run = sys.argv[1], sys.argv[2]
if not os.path.exists(f): sys.exit(1)
for r in csv.DictReader(open(f, encoding="utf-8")):
    if r.get("run") == run and str(r.get("check", "")).startswith("ok"): sys.exit(0)
sys.exit(1)
PY
}
# tiến trình hỗ trợ (chạy nền, bỏ qua nếu đã chạy)
powershell -NoProfile -Command "Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','orange\scripts\keep_awake.ps1','-MaxHours','24','-IntervalSec','30'" >/dev/null 2>&1
powershell -NoProfile -Command "Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','orange\scripts\watchdog.ps1','-MinFreeGB','1.5','-IntervalSec','10','-MaxHours','24'" >/dev/null 2>&1
(nohup python -I orange/scripts/hang_guard.py 7800 > orange/results/log-hang-guard-console.txt 2>&1 &)
say "da bat keep_awake, watchdog, hang_guard"

if have_ok orange/results/setA-04-P2-pc-r6-6b.csv 6; then say "setA-04 t=0,1 seed 6 da co, bo qua"; else
  wait_ram 9; say "BAT DAU setA-04 t=0,1 seed 6"
  julia --project=orange orange/scripts/run_experiments.jl 2 3600 4 4 pc 6 6 -r6-6b 12 > orange/results/log-pc-P2-04-r6-6b.txt 2>&1
  say "KET THUC setA-04 t=0,1 seed 6 (ma thoat $?)"; fi
if have_ok orange/results/setA-05-P2-pc-r10-10b.csv 10; then say "setA-05 t=0,1 seed 10 da co, bo qua"; else
  wait_ram 12; say "BAT DAU setA-05 t=0,1 seed 10"
  julia --project=orange orange/scripts/run_experiments.jl 2 3600 5 5 pc 10 10 -r10-10b 12 > orange/results/log-pc-P2-05-r10-10b.txt 2>&1
  say "KET THUC setA-05 t=0,1 seed 10 (ma thoat $?)"; fi
if have_ok orange/results/setA-04-P1-pc-r4-4v.csv 4; then say "setA-04 t=0 seed 4 (chay lai) da co, bo qua"; else
  wait_ram 4; say "BAT DAU setA-04 t=0 seed 4 chay lai"
  julia --project=orange orange/scripts/run_experiments.jl 1 1800 4 4 pc 4 4 -r4-4v 12 > orange/results/log-pc-P1-04-r4-4v.txt 2>&1
  say "KET THUC setA-04 t=0 seed 4 chay lai (ma thoat $?)"; fi
say "XONG-RESUME: sau do chay tren orange/results: best_known.jl, official_tables.jl, verify_srpaths.py, make_manifest.py, roi commit"
