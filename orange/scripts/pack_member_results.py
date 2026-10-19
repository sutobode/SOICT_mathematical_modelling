"""Gói kết quả của MỘT thành viên để gửi lại (chạy trên máy của thành viên đó, sau khi chạy xong phần được giao).

Chạy:  python orange/scripts/pack_member_results.py <ten_thanh_vien>
Tạo:   member_results/<ten>_<ngày_giờ>.zip  gồm: các file CSV có hậu tố khoảng chạy (-r5-7 ...), log solver trong
       solverlogs/, log chạy log-*.txt, environment-<ten>.txt (nếu có) và danh sách SHA-256 của chúng.
Người điều phối giải nén vào orange/results/ rồi chạy `julia orange/scripts/official_tables.jl`.
"""
import glob
import hashlib
import os
import re
import sys
import zipfile
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
RES = os.path.join(ROOT, "orange", "results")


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for c in iter(lambda: f.read(1 << 20), b""):
            h.update(c)
    return h.hexdigest()


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    who = re.sub(r"[^A-Za-z0-9_-]", "", sys.argv[1])
    files = []
    files += [f for f in glob.glob(os.path.join(RES, "setA-*-r[0-9]*-[0-9]*.csv"))]          # kết quả các lần chạy (cả -loads.csv)
    files += glob.glob(os.path.join(RES, "setA-*-r[0-9]*-[0-9]*-*.csv"))
    files += glob.glob(os.path.join(RES, "setA-*-r[0-9]*-[0-9]*-srpaths.json"))               # nghiệm của lần chạy đầu trong khoảng
    files += glob.glob(os.path.join(RES, "solverlogs", "*.log"))
    files += glob.glob(os.path.join(RES, "log-*.txt"))
    env = os.path.join(RES, f"environment-{who}.txt")
    if os.path.exists(env):
        files.append(env)
    else:
        print(f"CANH BAO: chua co {env}; tao bang lenh trong project/HUONG_DAN_CHAY_SONG_SONG.md (muc 3.4)")
    os.makedirs(os.path.join(ROOT, "member_results"), exist_ok=True)
    out = os.path.join(ROOT, "member_results", f"{who}_{datetime.now():%Y%m%d_%H%M}.zip")
    lines = []
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for f in sorted(set(files)):
            rel = os.path.relpath(f, RES).replace(os.sep, "/")
            z.write(f, "results/" + rel)
            lines.append(f"{sha(f)}  {rel}")
        z.writestr("SHA256SUMS.txt", "\n".join(lines) + "\n")
    print(f"wrote {out} ({len(lines)} files)")


if __name__ == "__main__":
    main()
