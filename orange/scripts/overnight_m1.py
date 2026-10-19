"""Bộ lập lịch chạy đêm cho máy M1 (chạy tự động, có nhật ký truy vết `orange/results/overnight_m1.log`).

Kế hoạch: (A) chờ setA-04 ($t=0,1$) xong các lần 1..4 rồi DỪNG tiến trình đó (nhường RAM; các lần 5..10 do M2/M3 hoặc làm sau);
(B) chạy setA-05 ($t=0,1$) mô hình theo đề, seed 1..5, MỖI LẦN một tiến trình duy nhất; nếu tiến trình chết giữa chừng (thiếu RAM,
máy ngủ) thì tính lại các seed còn thiếu và chạy tiếp bằng khoảng con với hậu tố mới (không ghi đè).

Chạy:  python orange/scripts/overnight_m1.py <PID_tiến_trình_setA-04_t=0,1>
"""
import csv
import glob
import os
import subprocess
import sys
import time
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
RES = os.path.join(ROOT, "orange", "results")
LOGF = os.path.join(RES, "overnight_m1.log")
TARGET_05 = list(range(1, 6))            # seed của setA-05 ($t=0,1$) giao cho M1
NEED_FREE_GB = 12.0                      # RAM trống tối thiểu trước khi bắt đầu một khoảng của setA-05
MEM_BUDGET_GB = 12                       # ngân sách bộ nhớ truyền cho runner (ước lượng ~11,1 GB)


def log(msg):
    line = f"[{datetime.now():%Y-%m-%d %H:%M:%S}] {msg}"
    print(line, flush=True)
    with open(LOGF, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def done_seeds(pattern):
    seeds = set()
    for f in glob.glob(os.path.join(RES, pattern)):
        if f.endswith(("-loads.csv", "-smoke.csv")):
            continue
        try:
            for r in csv.DictReader(open(f, encoding="utf-8")):
                if r.get("run", "").isdigit() and r.get("status") in ("Optimal", "Not Optimal") and str(r.get("check", "")).startswith("ok"):
                    seeds.add(int(r["run"]))
        except Exception:  # noqa: BLE001
            pass
    return seeds


def free_gb():
    try:
        out = subprocess.run(["powershell", "-NoProfile", "-Command",
                              "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,2)"],
                             capture_output=True, text=True, timeout=60).stdout.strip()
        return float(out.replace(",", "."))
    except Exception:  # noqa: BLE001
        return 0.0


def alive(pid):
    out = subprocess.run(["powershell", "-NoProfile", "-Command", f"(Get-Process -Id {pid} -ErrorAction SilentlyContinue | Measure-Object).Count"],
                         capture_output=True, text=True).stdout.strip()
    return out == "1"


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    pid04 = int(sys.argv[1])
    log(f"start: PID setA-04 t=0,1 = {pid04}; M1 se chay setA-05 t=0,1 seed {TARGET_05[0]}..{TARGET_05[-1]}")

    # (A) chờ setA-04 t=0,1 xong lần 1..4 rồi dừng tiến trình
    while not {1, 2, 3, 4} <= done_seeds("setA-04-P2-pc*.csv"):
        time.sleep(60)
    log(f"setA-04 t=0,1: da co cac lan {sorted(done_seeds('setA-04-P2-pc*.csv'))}")
    if alive(pid04):
        subprocess.run(["powershell", "-NoProfile", "-Command", f"Stop-Process -Id {pid04} -Force"])
        log(f"da dung PID {pid04} (setA-04 t=0,1): cac lan 5..10 se do M2/M3 chay (hoac lam sau); nhuong RAM cho setA-05")
    time.sleep(10)

    # (B) setA-05 t=0,1 seed 1..5, tung khoang lien tiep, co the chay lai phan con thieu
    attempts = 0
    while attempts < 8:
        need = sorted(set(TARGET_05) - done_seeds("setA-05-P2-pc*.csv"))
        if not need:
            log("setA-05 t=0,1: du seed 1..5. Ket thuc.")
            return
        a = need[0]
        b = a
        while b + 1 in need:
            b += 1
        waited = 0
        while free_gb() < NEED_FREE_GB:
            if waited % 600 == 0:
                log(f"cho RAM trong >= {NEED_FREE_GB} GB (hien {free_gb():.1f} GB)")
            time.sleep(30)
            waited += 30
        suffix = f"-r{a}-{b}"
        logfile = os.path.join(RES, f"log-pc-P2-05{suffix}.txt")
        env = dict(os.environ, JULIA_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1")
        cmd = ["julia", "--project=orange", "orange/scripts/run_experiments.jl", "2", "3600", "5", "5", "pc", str(a), str(b), suffix, str(MEM_BUDGET_GB)]
        log(f"lan thu {attempts + 1}: {' '.join(cmd)}  (free RAM {free_gb():.1f} GB)")
        with open(logfile, "w", encoding="utf-8") as lf:
            p = subprocess.Popen(cmd, cwd=ROOT, env=env, stdout=lf, stderr=subprocess.STDOUT)
        try:
            subprocess.run(["powershell", "-NoProfile", "-Command", f"(Get-Process -Id {p.pid}).PriorityClass='BelowNormal'"], capture_output=True)
        except Exception:  # noqa: BLE001
            pass
        rc = p.wait()
        attempts += 1
        got = sorted(done_seeds("setA-05-P2-pc*.csv"))
        log(f"khoang {suffix} ket thuc (ma thoat {rc}); setA-05 t=0,1 da co cac lan {got}")
    log("dung sau 8 lan thu; kiem tra thu cong")


if __name__ == "__main__":
    main()
