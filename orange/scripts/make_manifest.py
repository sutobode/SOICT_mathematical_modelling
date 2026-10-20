"""Hồ sơ truy vết (traceability) cho mọi kết quả trong orange/results:

  MANIFEST.csv         mỗi file kết quả: kích thước, SHA-256, thời điểm ghi, commit mã nguồn gần nhất trước thời điểm đó
  MANIFEST_INPUTS.csv  SHA-256 của dữ liệu đầu vào project/setA/* (để chứng minh dùng đúng dữ liệu của thầy)
  MANIFEST.md          tóm tắt: commit hiện tại, môi trường, tham số solver, chính sách số lần chạy, các lệnh đã chạy,
                       cách kiểm tra lại một kết quả

Chạy: python -I orange/scripts/make_manifest.py     (an toàn để chạy lại nhiều lần)
"""
import csv
import glob
import hashlib
import os
import subprocess
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ORANGE = os.path.abspath(os.path.join(HERE, ".."))
ROOT = os.path.abspath(os.path.join(ORANGE, ".."))
RES = os.path.join(ORANGE, "results")
SETA = os.path.join(ROOT, "project", "setA")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def git(*args):
    return subprocess.run(["git", "-C", ROOT, *args], capture_output=True, text=True).stdout.strip()


def commits():
    """[(thời điểm commit (epoch), hash ngắn, tiêu đề)] sắp tăng dần theo thời gian."""
    out = git("log", "--format=%ct|%h|%s", "--reverse")
    res = []
    for line in out.splitlines():
        t, h, s = line.split("|", 2)
        res.append((int(t), h, s))
    return res


def commit_at(cs, mtime):
    best = None
    for t, h, s in cs:
        if t <= mtime:
            best = (h, s)
    return best or ("-", "-")


RUNS = [
    ("Bảng chính thức t=0 (bước 6), mô hình theo cung, r theo calculating_r.pdf",
     "julia --project=orange orange/scripts/run_experiments.jl 1 1800 1 20 pc   (instance 01–03; 04–20 chạy lại bằng `... 1 1800 4 20 pc`)",
     "setA-XX-P1-pc.csv, -srpaths.json, -loads.csv, log-pc-P1*.txt"),
    ("Bảng chính thức t=0,1 (bước 9), mô hình theo cung, r theo calculating_r.pdf",
     "julia --project=orange orange/scripts/run_experiments.jl 2 3600 1 20 pc",
     "setA-XX-P2-pc.csv, ..., log-pc-P2.txt"),
    ("Mô hình theo cung, r theo ECMP (kiểm chứng; kết quả trùng bảng chính thức)",
     "julia --project=orange orange/scripts/run_experiments.jl 1 1800  /  ... 2 3600 1 20 (một phần)",
     "setA-XX-P{1,2}.csv, log-P1.txt, log-P2.txt"),
    ("Mô hình waypoint, ứng viên theo độ vòng (tối ưu một waypoint khi K = n-2)",
     "julia --project=orange orange/scripts/run_wp.jl 1 1800 1 13  /  ... 2 3600 1 13 (dừng sớm vì trùng với sinh cột)",
     "setA-XX-wp-P{1,2}.csv, log-wp-P{1,2}.txt"),
    ("Mô hình waypoint + sinh cột (kết quả cho cả 20 instance)",
     "julia --project=orange orange/scripts/run_wp.jl 1 1800 1 20 1500000 cg  /  ... 2 3600 1 20 1500000 cg",
     "setA-XX-wp-P{1,2}-cg.csv, log-wp-cg-P{1,2}.txt"),
    ("Sinh cột với r theo công thức của thầy (chỉ instance khác ECMP: 18 và 20; 01–09 chạy thử)",
     "julia --project=orange orange/scripts/run_wp.jl <P> <giây> 18 18 1500000 cg pc  (và 20)",
     "setA-XX-wp-P{1,2}-cg-pc.csv, log-wp-cg-pc-*.txt"),
    ("Tinh chỉnh LNS cho instance còn gap lớn",
     "julia --project=orange orange/scripts/run_wp.jl 1 300 <i> <i> 1500000 cg ecmp lns  /  ... 2 300 <i> <i> 1500000 cg ecmp lns 900",
     "setA-XX-wp-P{1,2}-cg-lns.csv, log-wp-cg-lns-*.txt"),
    ("So sánh r theo ECMP và theo công thức của thầy",
     "julia --project=orange orange/scripts/r_difference.jl", "r_difference.csv"),
    ("Kiểm tra độc lập bằng Python", "python -I orange/scripts/verify_srpaths.py", "verification.csv"),
    ("Tổng hợp", "julia orange/scripts/best_known.jl ; julia orange/scripts/official_tables.jl",
     "best_known.csv, table_official_P{1,2}.md/.csv"),
]


def main():
    cs = commits()
    files = sorted(f for f in glob.glob(os.path.join(RES, "**", "*"), recursive=True)
                   if os.path.isfile(f) and os.path.basename(f) not in ("MANIFEST.csv", "MANIFEST_INPUTS.csv", "MANIFEST.md", "STATUS.md"))
    with open(os.path.join(RES, "MANIFEST.csv"), "w", newline="", encoding="utf-8") as fo:
        w = csv.writer(fo)
        w.writerow(["file", "bytes", "sha256", "modified", "code_commit", "code_commit_subject"])
        for f in files:
            mt = os.path.getmtime(f)
            h, s = commit_at(cs, mt)
            w.writerow([os.path.relpath(f, RES).replace(os.sep, "/"), os.path.getsize(f), sha256(f),
                        datetime.fromtimestamp(mt).strftime("%Y-%m-%d %H:%M:%S"), h, s])
    inputs = sorted(glob.glob(os.path.join(SETA, "*.json")))
    with open(os.path.join(RES, "MANIFEST_INPUTS.csv"), "w", newline="", encoding="utf-8") as fo:
        w = csv.writer(fo)
        w.writerow(["file", "bytes", "sha256"])
        for f in inputs:
            w.writerow(["project/setA/" + os.path.basename(f), os.path.getsize(f), sha256(f)])

    env = open(os.path.join(RES, "environment.txt"), encoding="utf-8", errors="replace").read() if os.path.exists(os.path.join(RES, "environment.txt")) else "(thiếu environment.txt)"
    env_head = "\n".join(env.splitlines()[:14])
    manifest_sha = sha256(os.path.join(ORANGE, "Manifest.toml")) if os.path.exists(os.path.join(ORANGE, "Manifest.toml")) else "-"
    lines = [
        "# Hồ sơ truy vết kết quả thực nghiệm\n",
        f"Tạo lúc: {datetime.now():%Y-%m-%d %H:%M:%S}\n",
        "## Phiên bản mã nguồn\n",
        f"- Repository: `{git('remote', 'get-url', 'origin')}`",
        f"- Nhánh: `{git('rev-parse', '--abbrev-ref', 'HEAD')}`; commit hiện tại: `{git('rev-parse', '--short', 'HEAD')}` ({git('log', '-1', '--format=%s')})",
        f"- Commit chưa lưu (thay đổi chưa commit trong `orange/src`): {len(git('status', '--short', 'orange/src').splitlines())} file",
        f"- SHA-256 của `orange/Manifest.toml` (khóa phiên bản thư viện Julia): `{manifest_sha}`\n",
        "## Môi trường\n",
        "```",
        env_head,
        "```\n",
        "## Tham số cố định của mọi lần chạy\n",
        "- Solver: HiGHS qua JuMP, **1 luồng** (`threads=1`), `mip_rel_gap = 1e-6`, `random_seed = số thứ tự lần chạy` (mô hình theo cung).",
        "- Hàm mục tiêu: min z + ε·Σx với ε = 1e-7/|D| (z là MLU); gap báo cáo = 1 − bound/obj trên cùng hàm mục tiêu.",
        "- Giới hạn thời gian: 1800 s cho chỉ t=0 (bước 6), 3600 s cho t=0,1 (bước 9). CPU time = `solve_time` của `optimize!` (thời gian thực, 1 luồng).",
        "- Số lần chạy: 10 nếu lần đầu giải trong 120 s, nếu không 3 lần (cột `run` trong CSV).",
        "- Mô hình theo cung bị bỏ qua (`SKIPPED_TOO_LARGE`) khi |D|·P·n·(n−1) > 3·10⁶ biến; khi đó dùng mô hình waypoint (bài toán hạn chế một waypoint).",
        "- Dung sai hòa khoảng cách khi tính r: 1e-9 tương đối. Khởi tạo MILP bằng nghiệm heuristic (thời gian ghi riêng, không tính vào CPU time).\n",
        "## Các lệnh đã chạy và file kết quả tương ứng\n",
        "| Mục đích | Lệnh | File kết quả |", "|---|---|---|",
    ]
    for p, c, f in RUNS:
        lines.append(f"| {p} | `{c}` | {f} |")
    lines += [
        "",
        "## Cách kiểm tra lại một kết quả\n",
        "1. **Dữ liệu đầu vào:** so SHA-256 của `project/setA/*.json` với `MANIFEST_INPUTS.csv`.",
        "2. **File kết quả:** so SHA-256 với `MANIFEST.csv`; cột `code_commit` là commit mã nguồn gần nhất trước khi file được ghi (`git show <commit>`).",
        "3. **Tính lại độc lập:** `python -I orange/scripts/verify_srpaths.py setA-04` đọc `*-srpaths.json` và tính lại ECMP, tải, MLU, ngân sách, maxSeg từ dữ liệu gốc (cài đặt riêng bằng Python); kết quả trong `verification.csv`.",
        "4. **Chạy lại một instance:** ví dụ `julia --project=orange orange/scripts/run_experiments.jl 1 1800 5 5 pc` (setA-05, t=0, r của thầy).",
        "5. **Kiểm thử mã nguồn:** `julia --project=orange orange/test/runtests.jl` (mô hình khớp vét cạn, r khớp Bảng 2 của đề).",
        "",
        "Lưu ý: một lần chạy dài bị gián đoạn bởi việc máy ngủ (Windows Modern Standby 18:40–19:10 ngày 19/10, xem `Kernel-Power` trong nhật ký hệ thống) có `solve_time` tính cả thời gian ngủ; "
        "các lần chạy này, nếu có, được đánh dấu trong báo cáo kết quả.",
    ]
    with open(os.path.join(RES, "MANIFEST.md"), "w", encoding="utf-8") as fo:
        fo.write("\n".join(lines) + "\n")
    print(f"MANIFEST: {len(files)} result files, {len(inputs)} input files")


if __name__ == "__main__":
    main()
