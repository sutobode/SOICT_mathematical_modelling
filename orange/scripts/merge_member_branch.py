"""Dành cho M1 (người điều phối): gộp kết quả mà một thành viên đã đẩy lên nhánh `results/<ten>` vào thư mục làm việc.

Chạy:  python orange/scripts/merge_member_branch.py <ten> [--remote origin] [--dry-run]
Ví dụ: python orange/scripts/merge_member_branch.py m2

Cách làm: `git fetch`, lấy danh sách file mà nhánh của thành viên THÊM MỚI so với nhánh hiện tại (chỉ trong orange/results/),
ghi các file đó vào thư mục làm việc. KHÔNG ghi đè file đã có: nếu file đã tồn tại và nội dung khác thì bỏ qua và cảnh báo
(chồng chéo/đặt tên trùng). Không commit, không đổi nhánh. Sau đó chạy các lệnh in ở cuối (manifest, bảng, kiểm chứng).
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))


def git(*args, binary=False):
    r = subprocess.run(["git", "-C", ROOT, *args], capture_output=True, text=not binary)
    return r.returncode, r.stdout, r.stderr


def main():
    argv = sys.argv[1:]
    remote = "origin"
    if "--remote" in argv:
        i = argv.index("--remote")
        remote = argv[i + 1]
        del argv[i:i + 2]
    dry = "--dry-run" in argv
    argv = [a for a in argv if not a.startswith("--")]
    if len(argv) != 1:
        print(__doc__)
        sys.exit(1)
    who = argv[0].lower()
    branch = f"results/{who}"
    rc, _, err = git("fetch", remote, branch)
    if rc != 0:
        print(f"Khong lay duoc {remote}/{branch}: {err.strip()}")
        sys.exit(1)
    ref = f"{remote}/{branch}"
    # Điểm xuất phát của thành viên: họ clone từ `main` rồi tạo nhánh results/<ten>, nên lấy merge-base với origin/main
    # (nếu main không có thì dùng HEAD). Như vậy chỉ thấy file họ THÊM, không lẫn thay đổi của main hay feature/tasr.
    base = ""
    for other in (f"{remote}/main", "HEAD"):
        rc, out, _ = git("merge-base", other, ref)
        if rc == 0 and out.strip():
            base = out.strip()
            break
    rc, out, err = git("diff", "--name-only", "--diff-filter=A", base, ref)
    files = [f for f in out.splitlines() if f.startswith("orange/results/")]
    new, same, conflict = [], [], []
    for f in files:
        local = os.path.join(ROOT, f)
        rc, content, _ = git("show", f"{ref}:{f}", binary=True)
        if rc != 0:
            continue
        if os.path.exists(local):
            if open(local, "rb").read() == content:
                same.append(f)
            else:
                conflict.append(f)
            continue
        new.append((f, content))
    print(f"Nhanh {ref}: {len(files)} file moi trong orange/results/; "
          f"{len(new)} se ghi, {len(same)} da co (giong nhau), {len(conflict)} TRUNG TEN NHUNG KHAC NOI DUNG")
    for f in conflict:
        print("  CANH BAO (bo qua, kiem tra chong cheo):", f)
    if dry:
        for f, _ in new:
            print("  +", f)
        print("(dry-run: khong ghi gi)")
        sys.exit(0)
    for f, content in new:
        local = os.path.join(ROOT, f)
        os.makedirs(os.path.dirname(local), exist_ok=True)
        open(local, "wb").write(content)
        print("  +", f)
    print("\nTiep theo:\n  python -I orange/scripts/make_manifest.py\n  julia orange/scripts/best_known.jl\n"
          "  julia orange/scripts/official_tables.jl      # canh bao neu trung so lan chay\n  python -I orange/scripts/verify_srpaths.py")
    sys.exit(3 if conflict else 0)


if __name__ == "__main__":
    main()
