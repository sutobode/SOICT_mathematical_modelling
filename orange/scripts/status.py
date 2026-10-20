"""Trang theo dõi tiến độ thực nghiệm: ghi orange/results/STATUS.md (và in ra màn hình).

Gồm: giờ, RAM trống, các tiến trình Julia, dòng cuối của từng log, bảng kết quả từng CSV (số lần chạy, trạng thái,
MLU, thời gian, gap) và các lần watchdog đã can thiệp.

Chạy một lần:   python -I orange/scripts/status.py
Tự cập nhật:    python -I orange/scripts/status.py --loop 60 --hours 24     (mỗi 60 giây)
"""
import csv
import glob
import os
import re
import subprocess
import sys
import time
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(HERE, "..", "results")


def sh(cmd):
    try:
        return subprocess.run(["powershell", "-NoProfile", "-Command", cmd], capture_output=True, text=True, timeout=30).stdout.strip()
    except Exception as e:  # noqa: BLE001
        return f"(không đọc được: {e})"


def tail(path, n=1):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            lines = [l.rstrip() for l in f.readlines() if l.strip()]
        return lines[-n:]
    except OSError:
        return []


def fnum(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return float("nan")


def describe(fname):
    b = os.path.basename(fname)[:-4]
    m = re.match(r"(setA-\d+)-(wp-)?P(\d)(.*)", b)
    if not m:
        return None
    name, wp, P, tag = m.groups()
    kind = "waypoint" if wp else "theo cung"
    tags = tag.strip("-")
    desc = kind + (f" [{tags}]" if tags else "")
    return name, int(P), desc


def summarize(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        rows = list(csv.DictReader(f))
    if not rows:
        return None
    st = [r.get("status", "") for r in rows]
    mlus = [fnum(r.get("mlu")) for r in rows]
    mlus = [x for x in mlus if x == x]
    times = [fnum(r.get("solve_time")) for r in rows]
    times = [x for x in times if x == x]
    gaps = [fnum(r.get("gap")) for r in rows]
    gaps = [x for x in gaps if x == x]
    return {
        "runs": len(rows),
        "status": max(set(st), key=st.count),
        "mlu": min(mlus) if mlus else float("nan"),
        "time": sum(times) / len(times) if times else float("nan"),
        "gap": max(gaps) if gaps else float("nan"),
        "age": (time.time() - os.path.getmtime(path)) / 60,
    }


def build():
    out = []
    out.append(f"# Trạng thái thực nghiệm\n\nCập nhật: **{datetime.now():%Y-%m-%d %H:%M:%S}**\n")
    ram = sh("[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)")
    out.append(f"RAM trống: **{ram} GB**\n")
    procs = sh("Get-Process julia -ErrorAction SilentlyContinue | Sort-Object StartTime | ForEach-Object { 'PID {0} | start {1:HH:mm} | RAM {2:N2} GB | CPU {3:N0}s' -f $_.Id, $_.StartTime, ($_.WorkingSet64/1GB), $_.CPU }")
    out.append("## Tiến trình Julia\n\n```\n" + (procs or "(không có)") + "\n```\n")

    out.append("## Dòng cuối của log\n")
    for lg in sorted(glob.glob(os.path.join(RES, "log-*.txt"))):
        t = tail(lg)
        age = (time.time() - os.path.getmtime(lg)) / 60
        out.append(f"- `{os.path.basename(lg)}` (ghi {age:.0f} phút trước): {t[0] if t else '(trống)'}")
    out.append("")

    out.append("## Kết quả đã có (mỗi dòng một file CSV)\n")
    out.append("| Instance | t | Loại | Lần chạy | Trạng thái | MLU tốt nhất | Thời gian TB (s) | Gap lớn nhất | Cập nhật (phút trước) |")
    out.append("|---|---|---|---|---|---|---|---|---|")
    files = [f for f in glob.glob(os.path.join(RES, "setA-*.csv")) if not f.endswith("-loads.csv")]
    items = []
    for f in files:
        d = describe(f)
        if d is None:
            continue
        s = summarize(f)
        if s:
            items.append((d, s))
    items.sort(key=lambda x: (x[0][2], x[0][1], x[0][0]))
    for (name, P, desc), s in items:
        out.append(f"| {name} | {P-1 if P == 1 else '0,1'} | {desc} | {s['runs']} | {s['status']} | {s['mlu']:.5f} | {s['time']:.1f} | {s['gap']:.2e} | {s['age']:.0f} |")
    out.append("")
    wd = tail(os.path.join(RES, "watchdog.log"), 3)
    out.append("## Watchdog RAM (3 dòng cuối)\n\n```\n" + "\n".join(wd) + "\n```\n")
    return "\n".join(out)


def brief():
    """Tóm tắt ngắn: giờ, RAM, log còn hoạt động và các CSV vừa thay đổi trong 20 phút gần nhất."""
    lines = [f"[{datetime.now():%H:%M}] RAM trống {sh('[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)')} GB; "
             f"tiến trình Julia: {sh('(Get-Process julia -ErrorAction SilentlyContinue | Measure-Object).Count')}"]
    for lg in sorted(glob.glob(os.path.join(RES, "log-*.txt"))):
        age = (time.time() - os.path.getmtime(lg)) / 60
        if age < 75:
            t = tail(lg)
            lines.append(f"  log {os.path.basename(lg)[4:-4]}: {t[0][:70] if t else ''} (ghi {age:.0f}p trước)")
    recent = []
    for f in glob.glob(os.path.join(RES, "setA-*.csv")):
        if f.endswith("-loads.csv"):
            continue
        d, sm = describe(f), None
        if d is None or (time.time() - os.path.getmtime(f)) / 60 > 20:
            continue
        sm = summarize(f)
        if sm:
            recent.append(f"  mới: {d[0]} t={'0' if d[1] == 1 else '0,1'} {d[2]}: {sm['runs']} lần, {sm['status']}, MLU {sm['mlu']:.5f}, {sm['time']:.0f}s")
    lines += sorted(recent) or ["  (không có CSV nào thay đổi trong 20 phút qua)"]
    return chr(10).join(lines)


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:  # noqa: BLE001
        pass
    if "--brief" in sys.argv:
        print(brief())
        return
    loop = 0
    hours = 24.0
    if "--loop" in sys.argv:
        loop = int(sys.argv[sys.argv.index("--loop") + 1])
    if "--hours" in sys.argv:
        hours = float(sys.argv[sys.argv.index("--hours") + 1])
    end = time.time() + hours * 3600
    while True:
        text = build()
        with open(os.path.join(RES, "STATUS.md"), "w", encoding="utf-8") as f:
            f.write(text)
        if not loop:
            print(text)
            return
        if time.time() > end:
            return
        time.sleep(loop)


if __name__ == "__main__":
    main()
