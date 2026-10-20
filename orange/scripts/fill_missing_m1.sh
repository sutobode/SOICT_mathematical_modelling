#!/bin/bash
# M1 tự chạy nốt các lần còn thiếu của Bảng 2 (khi M2/M3 chưa chạy), mỗi lần MỘT tiến trình, tuần tự.
# Thứ tự: setA-04 t=0,1 lần 5..10 (~8 GB), rồi setA-05 t=0,1 seed 6..10 (cần >= 12 GB RAM trống).
# Mỗi lần ghi vào file riêng (hậu tố -rK-K), không ghi đè. Nhật ký: orange/results/fill_missing_m1.log
cd "$(dirname "$0")/../.." || exit 1
LOG=orange/results/fill_missing_m1.log
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
say() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }
free_gb() { powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)" | tr -d '\r' | tr ',' '.'; }
have() { # have <csv-glob> <run>: đã có lần chạy này (check=ok)?
  python -I - "$1" "$2" <<'EOF'
import csv, glob, sys
pat, run = sys.argv[1], sys.argv[2]
for f in glob.glob(pat):
    if f.endswith(("-loads.csv", "-smoke.csv")):
        continue
    for r in csv.DictReader(open(f, encoding="utf-8")):
        if r.get("run") == run and str(r.get("check", "")).startswith("ok"):
            sys.exit(0)
sys.exit(1)
EOF
}
run_one() { # run_one <inst_index> <name> <seed> <need_free_gb>
  local idx=$1 name=$2 s=$3 need=$4
  if have "orange/results/setA-${name}-P2-pc*.csv" "$s"; then say "setA-$name seed $s: da co, bo qua"; return; fi
  while python -c "import sys; sys.exit(0 if float('$(free_gb)') >= $need else 1)"; [ $? -ne 0 ]; do
    say "cho RAM trong >= $need GB (hien $(free_gb) GB) truoc setA-$name seed $s"; sleep 120
  done
  say "BAT DAU setA-$name t=0,1 seed $s (free RAM $(free_gb) GB)"
  julia --project=orange orange/scripts/run_experiments.jl 2 3600 "$idx" "$idx" pc "$s" "$s" "-r${s}-${s}" 12 \
    > "orange/results/log-pc-P2-${name}-r${s}-${s}.txt" 2>&1
  say "KET THUC setA-$name seed $s (ma thoat $?)"
}
for s in 5 6 7 8 9 10; do run_one 4 04 "$s" 9; done
for s in 6 7 8 9 10; do run_one 5 05 "$s" 12; done
say "XONG: setA-04 lan 5-10 va setA-05 seed 6-10 (kiem tra lai bang status.py)"
