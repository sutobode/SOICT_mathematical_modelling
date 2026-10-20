#!/bin/bash
# Việc bù thứ hai của M1: setA-05 t=0,1 seed 10 (lần chạy bị watchdog dừng lúc 21:36 vì hết RAM), file -r10-10b.
# Chạy sau khi fill_followup_m1.sh xong (dòng XONG-VIEC-BU). Cần RAM trống >= 12 GB.
cd "$(dirname "$0")/../.." || exit 1
LOG=orange/results/fill_followup2_m1.log
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
say() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }
free_gb() { powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)" | tr -d '\r' | tr ',' '.'; }
say "cho fill_followup_m1.sh ket thuc"
until grep -q "XONG-VIEC-BU" orange/results/fill_followup_m1.log 2>/dev/null; do sleep 120; done
while python -c "import sys; sys.exit(0 if float('$(free_gb)') >= 12 else 1)"; [ $? -ne 0 ]; do say "cho RAM trong >= 12 GB (hien $(free_gb) GB)"; sleep 120; done
say "BAT DAU setA-05 t=0,1 seed 10 (lan bu)"
julia --project=orange orange/scripts/run_experiments.jl 2 3600 5 5 pc 10 10 -r10-10b 12 > orange/results/log-pc-P2-05-r10-10b.txt 2>&1
say "KET THUC setA-05 t=0,1 seed 10 bu (ma thoat $?)"
say "XONG-VIEC-BU-2"
