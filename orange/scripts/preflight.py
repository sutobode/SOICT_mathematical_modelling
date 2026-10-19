"""Kiểm tra máy TRƯỚC khi chạy thực nghiệm (dành cho thành viên và coding agent). Chỉ dùng thư viện chuẩn.

Chạy từ thư mục gốc của dự án:   python orange/scripts/preflight.py
In ra từng mục kiểm tra (OK / THIEU) và kết luận máy này có thể nhận việc nào:
  - setA-04 (t=0,1): cần RAM trống >= 12 GB      - setA-05 (t=0,1): cần RAM trống >= 16 GB
Mã thoát: 0 nếu mọi mục bắt buộc đều OK; 1 nếu thiếu mục bắt buộc.
"""
import glob
import os
import platform
import re
import shutil
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))


def run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=60).stdout.strip()
    except Exception:  # noqa: BLE001
        return ""


def ram_gb():
    """(tổng, trống) tính bằng GB."""
    sysname = platform.system()
    try:
        if sysname == "Windows":
            out = run(["powershell", "-NoProfile", "-Command",
                       "$o=Get-CimInstance Win32_OperatingSystem; ($o.TotalVisibleMemorySize/1MB).ToString('0.0') + ' ' + ($o.FreePhysicalMemory/1MB).ToString('0.0')"])
            t, f = out.split()
            return float(t.replace(",", ".")), float(f.replace(",", "."))
        if sysname == "Linux":
            m = dict(re.findall(r"(\w+):\s+(\d+) kB", open("/proc/meminfo").read()))
            return int(m["MemTotal"]) / 1048576, int(m.get("MemAvailable", m["MemFree"])) / 1048576
        if sysname == "Darwin":
            total = int(run(["sysctl", "-n", "hw.memsize"])) / 2**30
            vm = run(["vm_stat"])
            page = int(re.search(r"page size of (\d+)", vm).group(1))
            free = sum(int(re.search(rf"{k}:\s+(\d+)", vm).group(1)) for k in ("Pages free", "Pages inactive")) * page / 2**30
            return total, free
    except Exception:  # noqa: BLE001
        pass
    return float("nan"), float("nan")


def main():
    ok_all = True

    def item(name, ok, detail="", required=True):
        nonlocal ok_all
        print(f"[{'OK   ' if ok else 'THIEU'}] {name}{(': ' + detail) if detail else ''}")
        if required and not ok:
            ok_all = False

    print(f"He dieu hanh: {platform.platform()} | Python {sys.version.split()[0]} | thu muc: {ROOT}")
    julia = shutil.which("julia")
    ver = run([julia, "--version"]) if julia else ""
    item("Julia 1.13.x", bool(re.search(r"1\.13\.", ver)), ver or "khong tim thay lenh julia (cai bang juliaup: juliaup add 1.13.1)")
    item("orange/Project.toml + Manifest.toml", os.path.exists(os.path.join(ROOT, "orange", "Manifest.toml")))
    n_json = len(glob.glob(os.path.join(ROOT, "project", "setA", "*.json")))
    item("du lieu SetA (60 file json)", n_json == 60, f"{n_json} file")
    item("script chay", os.path.exists(os.path.join(ROOT, "orange", "scripts", "run_experiments.jl")))
    os.makedirs(os.path.join(ROOT, "orange", "results"), exist_ok=True)
    free_disk = shutil.disk_usage(ROOT).free / 2**30
    item("o cung trong >= 2 GB", free_disk >= 2, f"{free_disk:.1f} GB")
    total, free = ram_gb()
    item("RAM tong >= 16 GB", total >= 16, f"tong {total:.1f} GB", required=False)
    print(f"RAM trong luc nay: {free:.1f} GB (dong trinh duyet va ung dung nang de tang)")
    print("--- Ket luan ---")
    print(f"setA-04 (t=0,1; dinh ~8 GB):  {'CO THE nhan' if free >= 12 else 'CHUA du RAM trong (can >= 12 GB trong; dong ung dung va chay lai)'}")
    print(f"setA-05 (t=0,1; ~11-14 GB):   {'CO THE nhan' if free >= 16 else 'CHUA du RAM trong (can >= 16 GB trong; neu khong du thi KHONG nhan setA-05)'}")
    print("Thieu muc bat buoc -> sua truoc khi chay." if not ok_all else "Cac muc bat buoc deu OK.")
    sys.exit(0 if ok_all else 1)


if __name__ == "__main__":
    main()
