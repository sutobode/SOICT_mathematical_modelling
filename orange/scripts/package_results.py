"""Đóng gói toàn bộ orange/results thành một file zip có đóng dấu thời gian (để làm báo cáo và để sao lưu).

Chạy: python -I orange/scripts/package_results.py [thư mục đích] [số bản giữ lại]
Mặc định: thư mục đích = C:/Users/X1/Project/SOICT_results_backup (ngoài kho git), giữ 6 bản mới nhất.
Zip gồm mọi CSV, srpaths.json, bảng chính thức, best_known, verification, log, environment, STATUS và
orange/README.md + project/BAI_TOAN_FINAL.md + project/KE_HOACH_THUC_HIEN.md để người viết báo cáo có đủ ngữ cảnh.
"""
import glob
import os
import subprocess
import sys
import zipfile
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.abspath(os.path.join(HERE, "..", "results"))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))


def main():
    dest = sys.argv[1] if len(sys.argv) > 1 else "C:/Users/X1/Project/SOICT_results_backup"
    keep = int(sys.argv[2]) if len(sys.argv) > 2 else 6
    os.makedirs(dest, exist_ok=True)
    # làm mới hồ sơ truy vết (SHA-256, commit mã nguồn) trước khi đóng gói
    subprocess.run([sys.executable, "-I", os.path.join(HERE, "make_manifest.py")], capture_output=True)
    name = os.path.join(dest, f"ket_qua_{datetime.now():%Y%m%d_%H%M}.zip")
    n = 0
    with zipfile.ZipFile(name, "w", zipfile.ZIP_DEFLATED) as z:
        for f in sorted(glob.glob(os.path.join(RES, "**", "*"), recursive=True)):
            if os.path.isfile(f):
                z.write(f, os.path.join("results", os.path.relpath(f, RES)))
                n += 1
        for extra in ("orange/README.md", "project/BAI_TOAN_FINAL.md", "project/KE_HOACH_THUC_HIEN.md", "project/readme"):
            p = os.path.join(ROOT, extra)
            if os.path.isfile(p):
                z.write(p, extra)
                n += 1
    old = sorted(glob.glob(os.path.join(dest, "ket_qua_*.zip")))
    for f in old[:-keep]:
        os.remove(f)
    print(f"wrote {name} ({n} files, {os.path.getsize(name) / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
