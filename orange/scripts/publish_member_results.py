"""Đưa KẾT QUẢ của một thành viên lên nhánh git riêng `results/<ten>` (thao tác git DUY NHẤT mà thành viên được phép làm).

Chạy:  python orange/scripts/publish_member_results.py <ten> [--dry-run]
Ví dụ: python orange/scripts/publish_member_results.py m2

An toàn:
  - Từ chối chạy nếu có file mã nguồn/tài liệu đã bị SỬA (chỉ cho phép file mới trong orange/results/).
  - Chỉ `git add` đúng các file kết quả của thành viên: setA-*-r<a>-<b>*.csv/json, solverlogs/*.log, log-*.txt mới,
    environment-<ten>.txt. Không bao giờ đụng tới nhánh main hay feature/tasr; không `--force`.
  - Mỗi thành viên có nhánh riêng nên không bao giờ xung đột với nhau.
  - `--dry-run`: chỉ in những gì sẽ làm.
Nếu `git push` bị từ chối (chưa có quyền ghi): kết quả vẫn nằm trong commit cục bộ trên nhánh results/<ten>;
dùng `python orange/scripts/pack_member_results.py <ten>` để tạo file zip gửi người điều phối.
"""
import fnmatch
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
ALLOWED = [
    "orange/results/setA-*-r[0-9]*-[0-9]*.csv",
    "orange/results/setA-*-r[0-9]*-[0-9]*-*.csv",
    "orange/results/setA-*-r[0-9]*-[0-9]*-srpaths.json",
    "orange/results/solverlogs/*.log",
    "orange/results/log-*.txt",
]


def git(*args):
    r = subprocess.run(["git", "-C", ROOT, *args], capture_output=True, text=True)
    return r.returncode, r.stdout.strip(), r.stderr.strip()


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    if len(args) != 1:
        print(__doc__)
        sys.exit(1)
    who = re.sub(r"[^A-Za-z0-9_-]", "", args[0]).lower()
    allowed = ALLOWED + [f"orange/results/environment-{who}.txt"]

    rc, out, err = git("status", "--porcelain", "--untracked-files=all")
    if rc != 0:
        print("Khong phai thu muc git:", err)
        sys.exit(1)
    modified, candidates = [], []
    for line in out.splitlines():
        code, path = line[:2], line[3:].strip().strip('"')
        if code == "??":
            if any(fnmatch.fnmatch(path, pat) for pat in allowed):
                candidates.append(path)
        else:
            modified.append(f"{code} {path}")
    if modified:
        print("TU CHOI: co file da duoc theo doi bi sua (khong duoc phep):")
        for m in modified:
            print("  ", m)
        print("Hay hoan tac cac thay doi do (khong sua ma nguon) roi chay lai.")
        sys.exit(2)
    if not candidates:
        print("Khong co file ket qua moi de dua len.")
        sys.exit(0)
    branch = f"results/{who}"
    print(f"Nhanh dich: {branch}; {len(candidates)} file se duoc them:")
    for c in sorted(candidates)[:40]:
        print("  +", c)
    if len(candidates) > 40:
        print(f"  ... va {len(candidates) - 40} file nua")
    if dry:
        print("(dry-run: khong lam gi)")
        sys.exit(0)
    rc, cur, _ = git("rev-parse", "--abbrev-ref", "HEAD")
    rc, _, _ = git("rev-parse", "--verify", branch)
    if rc == 0:
        rc, _, err = git("checkout", branch)
    else:
        rc, _, err = git("checkout", "-b", branch)
    if rc != 0:
        print("Khong chuyen duoc sang nhanh", branch, err)
        sys.exit(1)
    for c in candidates:
        git("add", "--", c)
    rc, _, err = git("commit", "-m", f"results: {who} runs ({len(candidates)} files)")
    if rc != 0:
        print("Commit that bai:", err)
        sys.exit(1)
    rc, o, err = git("push", "-u", "origin", branch)
    if rc != 0:
        print("PUSH BI TU CHOI hoac loi:", err)
        print(f"Ket qua da nam trong commit cuc bo tren nhanh {branch}. Dung pack_member_results.py de gui file zip thay the.")
        sys.exit(3)
    print(f"Da dua ket qua len origin/{branch}. Thong bao nguoi dieu phoi.")


if __name__ == "__main__":
    main()
