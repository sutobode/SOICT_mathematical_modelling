"""Kiểm tra kết quả của MỘT khoảng chạy (dành cho thành viên và coding agent). Chỉ dùng thư viện chuẩn.

Chạy:  python orange/scripts/check_range.py <file.csv> <seed_đầu> <seed_cuối>
Ví dụ: python orange/scripts/check_range.py orange/results/setA-04-P2-pc-r5-7.csv 5 7
In từng lần chạy (run, status, mlu, solve_time, check) và kết luận:
  COMPLETE    : có đủ các lần seed_đầu..seed_cuối, mọi dòng check=ok       (mã thoát 0)
  INCOMPLETE  : còn thiếu lần chạy (liệt kê các lần thiếu)                  (mã thoát 2)
  PROBLEM     : có dòng ERROR / SKIPPED_* / check khác ok / trùng số lần    (mã thoát 3)
"""
import csv
import os
import sys


def main():
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)
    path, a, b = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    if not os.path.exists(path):
        print(f"INCOMPLETE: chua co file {path} (lan chay dau tien chua xong)")
        sys.exit(2)
    rows = list(csv.DictReader(open(path, encoding="utf-8")))
    seen, problems = {}, []
    for r in rows:
        run = int(r["run"]) if r.get("run", "").lstrip("-").isdigit() else None
        print(f"run={r.get('run'):>3}  status={r.get('status'):<12} mlu={r.get('mlu')}  solve_time={r.get('solve_time')}  check={r.get('check')}")
        if run in seen:
            problems.append(f"trung so lan chay {run}")
        seen[run] = r
        if r.get("status") not in ("Optimal", "Not Optimal"):
            problems.append(f"run {run}: status {r.get('status')}")
        elif not str(r.get("check", "")).startswith("ok"):
            problems.append(f"run {run}: check = {r.get('check')}")
    missing = [i for i in range(a, b + 1) if i not in seen]
    extra = [i for i in seen if i is not None and not (a <= i <= b)]
    if extra:
        problems.append(f"co lan chay ngoai khoang duoc giao: {extra}")
    if problems:
        print("PROBLEM:", "; ".join(problems))
        sys.exit(3)
    if missing:
        print(f"INCOMPLETE: da co {sorted(k for k in seen if k is not None)}, con thieu {missing}")
        sys.exit(2)
    print(f"COMPLETE: du cac lan {a}..{b}, tat ca check=ok")
    sys.exit(0)


if __name__ == "__main__":
    main()
