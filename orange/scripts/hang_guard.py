"""Bảo vệ chuỗi chạy dài: dừng tiến trình `run_experiments.jl` chạy quá lâu so với giới hạn.

Lý do: HiGHS đôi khi vượt giới hạn thời gian rất xa (đã gặp: setA-05 t=0,1 seed 5 mất 7175 s; setA-04 t=0,1 seed 6 quá 100 phút
mà log solver không in thêm dòng nào). Một lần chạy treo sẽ chặn cả chuỗi. Lần chạy bị dừng KHÔNG ghi dòng CSV nào (kết quả
của seed đó bị bỏ), chuỗi `fill_missing_m1.sh` tự chuyển sang seed kế tiếp; seed bị bỏ có thể chạy bù bằng khoảng con sau.

Chạy:  python orange/scripts/hang_guard.py [giây_tối_đa=7800]
Chỉ giám sát tiến trình julia khởi động SAU khi guard chạy (tiến trình có sẵn như julia của IDE không bao giờ bị dừng).
Nhật ký: orange/results/hang_guard.log. Chỉ dừng tiến trình julia có dòng lệnh chứa `run_experiments.jl`
(không bao giờ đụng tiến trình julia của IDE).
"""
import os
import subprocess
import sys
import time
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(HERE, "..", "results", "hang_guard.log")
MAX_SEC = float(sys.argv[1]) if len(sys.argv) > 1 else 7800.0
EXCLUDE = {int(a) for a in sys.argv[2:]}
T0 = time.time()   # chỉ giám sát tiến trình julia KHỞI ĐỘNG SAU thời điểm này (tiến trình có sẵn, ví dụ julia của IDE, không bị đụng tới)

PS = (
    "Get-Process julia -ErrorAction SilentlyContinue | ForEach-Object { "
    "'{0}|{1}' -f $_.Id, [int]((Get-Date) - $_.StartTime).TotalSeconds }"
)


def log(msg):
    line = f"[{datetime.now():%Y-%m-%d %H:%M:%S}] {msg}"
    print(line, flush=True)
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def main():
    log(f"hang_guard bat dau: dung tien trinh julia chay qua {MAX_SEC:.0f} s (loai tru PID {sorted(EXCLUDE)})")
    while True:
        try:
            out = subprocess.run(["powershell", "-NoProfile", "-Command", PS], capture_output=True, text=True, timeout=120).stdout
        except Exception as e:  # noqa: BLE001
            log(f"loi khi liet ke tien trinh: {e}")
            time.sleep(60)
            continue
        for line in out.split():
            try:
                pid, age = line.split("|")
                pid, age = int(pid), float(age)
            except ValueError:
                continue
            predates_guard = age > time.time() - T0 + 5      # tiến trình có trước khi guard chạy
            if pid not in EXCLUDE and not predates_guard and age > MAX_SEC:
                subprocess.run(["powershell", "-NoProfile", "-Command", f"Stop-Process -Id {pid} -Force"], capture_output=True)
                log(f"DA DUNG PID {pid} (chay {age:.0f} s > {MAX_SEC:.0f} s); seed do khong co dong CSV; chuoi chuyen sang seed ke tiep")
        time.sleep(60)


if __name__ == "__main__":
    main()
