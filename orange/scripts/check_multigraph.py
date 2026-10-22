"""Kiểm tra độc lập (Python, chỉ thư viện chuẩn): SetA của thầy có thật sự là đa đồ thị (multigraph) không?

Chạy:  python orange/scripts/check_multigraph.py          (hoặc `python -I ...`)
Mã thoát 0 nếu cả 20 instance KHÔNG có cung song song, khuyên, id trùng hay đầu mút không tồn tại; 2 nếu có vi phạm.

Lưu ý: cờ `"multigraph": true` trong file NetworkX chỉ là thuộc tính của định dạng, không có nghĩa là có cung song song.
Cung song song = hai link khác nhau có CÙNG cặp có thứ tự (from, to). Hai cung ngược chiều (a->b và b->a) là hợp lệ trong
đồ thị có hướng và KHÔNG phải cung song song.
"""
import collections
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SETA = os.path.join(HERE, "..", "..", "project", "setA")


def analyse(net, scenario):
    links, nodes = net["links"], net["nodes"]
    node_ids = [n["id"] for n in nodes]
    link_ids = [l["id"] for l in links]
    pairs = collections.Counter((l["from"], l["to"]) for l in links)
    parallel = {p: c for p, c in pairs.items() if c > 1}
    loops = [l["id"] for l in links if l["from"] == l["to"]]
    pset = set(pairs)
    anti = sum(1 for (a, b) in pset if a < b and (b, a) in pset)
    problems = []
    if len(set(node_ids)) != len(node_ids):
        problems.append("id nút trùng")
    if len(set(link_ids)) != len(link_ids):
        problems.append("id link trùng")
    if any(l["from"] not in set(node_ids) or l["to"] not in set(node_ids) for l in links):
        problems.append("đầu mút không phải nút có thật")
    if parallel:
        problems.append(f"{len(parallel)} nhóm cung song song, ví dụ {next(iter(parallel))}")
    if loops:
        problems.append(f"{len(loops)} khuyên")
    down_ids = [i for iv in scenario.get("interventions", []) for i in iv.get("links", [])]
    if any(i not in set(link_ids) for i in down_ids):
        problems.append("id cung bị tắt không tồn tại")
    return dict(declared=bool(net.get("multigraph", False)), directed=bool(net.get("directed", False)), n=len(nodes),
                m=len(links), distinct_pairs=len(pairs), parallel=len(parallel), loops=len(loops), anti=anti, problems=problems)


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")   # console Windows (cp1252) không in được tiếng Việt
    except Exception:
        pass
    nets = sorted(glob.glob(os.path.join(SETA, "setA-*-net.json")))
    if len(nets) != 20:
        print(f"CẢNH BÁO: tìm thấy {len(nets)} file net, mong đợi 20")
    print(f"{'instance':9s} {'multigraph?':12s} {'nút':>5s} {'link':>6s} {'cặp khác nhau':>14s} {'song song':>10s} {'khuyên':>7s} {'ngược chiều':>12s}")
    declared = actual = bad = 0
    for f in nets:
        name = re.match(r"(setA-\d+)-net\.json", os.path.basename(f)).group(1)
        net = json.load(open(f, encoding="utf-8"))
        sc = json.load(open(f.replace("-net.json", "-scenario.json"), encoding="utf-8"))
        r = analyse(net, sc)
        declared += r["declared"]
        actual += r["parallel"] > 0
        bad += bool(r["problems"]) or not r["directed"]
        print(f"{name:9s} {str(r['declared']):12s} {r['n']:5d} {r['m']:6d} {r['distinct_pairs']:14d} {r['parallel']:10d} {r['loops']:7d} {r['anti']:12d}"
              + (f"   <-- {'; '.join(r['problems'])}" if r["problems"] else ""))
    print(f"\nKhai báo multigraph=true: {declared}/{len(nets)}.  Thật sự có cung song song: {actual}/{len(nets)}.  Instance có vi phạm khác: {bad}.")
    if actual == 0 and bad == 0:
        print("KẾT LUẬN: không instance nào của SetA là đa đồ thị thật; cờ multigraph=true chỉ là thuộc tính định dạng.")
        return 0
    print("KẾT LUẬN: CÓ vi phạm, xem các dòng đánh dấu ở trên.")
    return 2


if __name__ == "__main__":
    sys.exit(main())
