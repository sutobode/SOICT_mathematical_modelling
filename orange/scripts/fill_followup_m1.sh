#!/bin/bash
# Việc bù của M1, chạy NGAY SAU KHI chuỗi fill_missing_m1.sh xong (mỗi lần một tiến trình):
#   1) setA-04 t=0,1 seed 6 (lần chạy bị bỏ vì quá giờ) -> file -r6-6b (số thứ tự lần chạy vẫn là 6)
#   2) setA-04 t=0 seed 4 chạy lại để có nghiệm kiểm chứng cho giá trị 0,50105 của bảng (file -r4-4v, KHÔNG gộp vào bảng:
#      tên không khớp mẫu -rA-B; chỉ dùng làm bằng chứng; nếu tái hiện đúng 0,50105 thì nghiệm của nó đi kèm bảng)
# Nhật ký: orange/results/fill_followup_m1.log
cd "$(dirname "$0")/../.." || exit 1
LOG=orange/results/fill_followup_m1.log
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
say() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }
free_gb() { powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)" | tr -d '\r' | tr ',' '.'; }
say "cho chuoi fill_missing_m1.sh ket thuc"
until grep -q "XONG:" orange/results/fill_missing_m1.log 2>/dev/null; do sleep 120; done
say "chuoi chinh da xong; bat dau viec bu"
wait_ram() { while python -c "import sys; sys.exit(0 if float('$(free_gb)') >= $1 else 1)"; [ $? -ne 0 ]; do say "cho RAM trong >= $1 GB (hien $(free_gb) GB)"; sleep 120; done; }
wait_ram 9
say "BAT DAU setA-04 t=0,1 seed 6 (lan bu)"
julia --project=orange orange/scripts/run_experiments.jl 2 3600 4 4 pc 6 6 -r6-6b 12 > orange/results/log-pc-P2-04-r6-6b.txt 2>&1
say "KET THUC setA-04 t=0,1 seed 6 bu (ma thoat $?)"
wait_ram 4
say "BAT DAU setA-04 t=0 seed 4 chay lai de co nghiem kiem chung"
julia --project=orange orange/scripts/run_experiments.jl 1 1800 4 4 pc 4 4 -r4-4v 12 > orange/results/log-pc-P1-04-r4-4v.txt 2>&1
say "KET THUC setA-04 t=0 seed 4 chay lai (ma thoat $?)"
say "XONG-VIEC-BU"
