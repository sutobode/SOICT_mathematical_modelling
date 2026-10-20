"""Bộ kiểm tra độc lập (Python, chỉ dùng thư viện chuẩn) cho các nghiệm `*-srpaths.json` trong orange/results.

Cài đặt lại từ đầu, không dùng code Julia: đọc net/tm/scenario gốc, tính ECMP từng chặng trên G_t (loại cung bị tắt),
tải của mọi cung, MLU, số đoạn (<= max_segments) và ngân sách (dist theo định nghĩa của đề), rồi so MLU với cột `mlu`
của CSV tương ứng. Mỗi nghiệm được kiểm tra với hai dung sai hòa khoảng cách (1e-9 và 1e-6) để phát hiện nghiệm nhạy
với sai số số học.

File có "-pc" trong tên (hệ số tách theo công thức đếm đường của calculating_r.pdf) được kiểm tra với r = sigma_iu*sigma_vj/sigma_ij,
các file còn lại với ECMP từng chặng (đúng định nghĩa của đề).

Chạy: python -I orange/scripts/verify_srpaths.py [mẫu tên file, ví dụ setA-0]   -> orange/results/verification.csv
"""
import csv
import glob
import heapq
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(HERE, "..", "results")
SETA = os.path.join(HERE, "..", "..", "project", "setA")


def isclose(a, b, tol):
    return abs(a - b) <= tol * max(1.0, abs(b)) + 1e-12


def load_instance(name):
    p = os.path.join(SETA, name)
    net = json.load(open(p + "-net.json"))
    tm = json.load(open(p + "-tm.json"))
    sc = json.load(open(p + "-scenario.json"))
    return net, tm, sc


class Period:
    """Đồ thị G_t: khoảng cách ngắn nhất và hàm chia ECMP, có nhớ theo (u, v)."""

    def __init__(self, net, down_ids, tol, mode="ecmp"):
        self.tol = tol
        self.mode = mode
        self.ids = [x["id"] for x in net["nodes"]]
        self.out = {i: [] for i in self.ids}
        self.arcs = {}
        for l in net["links"]:
            if l["id"] in down_ids:
                continue
            self.out[l["from"]].append((l["id"], l["to"], float(l["metric"])))
            self.arcs[l["id"]] = (l["from"], l["to"])
        self.D = {}
        for s in self.ids:
            self.D[s] = self._dijkstra(s)
        self.memo = {}
        self.sigma = {}
        if mode == "pc":
            for s in self.ids:                       # số đường ngắn nhất từ s tới mọi nút (calculating_r.pdf, mục 1)
                order = sorted(self.D[s], key=lambda x: self.D[s][x])
                sg = {s: 1.0}
                for x in order:
                    for _, y, w in self.out[x]:
                        if y in self.D[s] and isclose(self.D[s][x] + w, self.D[s][y], tol):
                            sg[y] = sg.get(y, 0.0) + sg[x]
                self.sigma[s] = sg

    def _dijkstra(self, s):
        d = {s: 0.0}
        pq = [(0.0, s)]
        while pq:
            du, u = heapq.heappop(pq)
            if du > d.get(u, float("inf")):
                continue
            for _, v, w in self.out[u]:
                nd = du + w
                if nd < d.get(v, float("inf")):
                    d[v] = nd
                    heapq.heappush(pq, (nd, v))
        return d

    def split(self, u, v):
        key = (u, v)
        if key in self.memo:
            return self.memo[key]
        res = {}
        Duv = self.D[u].get(v)
        if u == v or Duv is None:
            self.memo[key] = res
            return res
        if self.mode == "pc":
            for x in self.D[u]:
                for i, y, w in self.out[x]:
                    if v in self.D[y] and isclose(self.D[u][x] + w + self.D[y][v], Duv, self.tol):
                        res[i] = self.sigma[u][x] * self.sigma[y][v] / self.sigma[u][v]
            self.memo[key] = res
            return res
        nodes = [x for x in self.D[u] if v in self.D[x] and isclose(self.D[u][x] + self.D[x][v], Duv, self.tol)]
        nodes.sort(key=lambda x: self.D[u][x])
        flow = {u: 1.0}
        for x in nodes:
            if x == v or x not in flow:
                continue
            outs = [(i, y) for (i, y, w) in self.out[x]
                    if v in self.D[y] and isclose(self.D[u][x] + w + self.D[y][v], Duv, self.tol)]
            if not outs:
                continue
            share = flow[x] / len(outs)
            for i, y in outs:
                res[i] = res.get(i, 0.0) + share
                flow[y] = flow.get(y, 0.0) + share
        self.memo[key] = res
        return res


def verify(name, P, srfile, tol, mode="ecmp"):
    net, tm, sc = load_instance(name)
    caps = {l["id"]: float(l["capacity"]) for l in net["links"]}
    down = [set() for _ in range(P)]
    for iv in sc["interventions"]:
        if iv["t"] < P:
            down[iv["t"]].update(iv["links"])
    budget = {b["t"]: b["value"] for b in sc["budget"]}
    maxseg = sc["max_segments"]
    nodes = {x["id"] for x in net["nodes"]}
    dem = tm["demands"]
    wp = {}
    for e in json.load(open(srfile))["srpaths"]:
        wp[(e["d"], e["t"])] = list(e["w"])
    periods = [Period(net, down[t], tol, mode) for t in range(P)]
    problems = []
    mlu = 0.0
    seqs = {}
    for t in range(P):
        load = {a: 0.0 for a in periods[t].arcs}
        for d, dd in enumerate(dem):
            w = wp.get((d, t), [])
            if any(x not in nodes for x in w):
                problems.append(f"demand {d} t={t}: unknown waypoint")
            seq = [dd["s"]] + w + [dd["t"]]
            seqs[(d, t)] = seq
            if len(seq) - 1 > maxseg:
                problems.append(f"demand {d} t={t}: {len(seq) - 1} segments > {maxseg}")
            for u, v in zip(seq, seq[1:]):
                sp = periods[t].split(u, v)
                if not sp and u != v:
                    problems.append(f"demand {d} t={t}: segment ({u},{v}) unreachable")
                for a, fr in sp.items():
                    load[a] += fr * dd["v"][t]
        mlu = max(mlu, max(load[a] / caps[a] for a in load))
    changes = {}
    for t in range(1, P):
        ch = 0
        for d in range(len(dem)):
            a = set(zip(seqs[(d, t - 1)], seqs[(d, t - 1)][1:]))
            b = set(zip(seqs[(d, t)], seqs[(d, t)][1:]))
            ch += len(a ^ b)
        changes[t] = ch
        if t in budget and ch > budget[t]:
            problems.append(f"budget violated at t={t}: {ch} > {budget[t]}")
    return mlu, changes, problems


def csv_mlu(srfile):
    """MLU của lần chạy đầu trong CSV tương ứng với file srpaths."""
    base = os.path.basename(srfile)
    runm = re.search(r"-run(\d+)-srpaths\.json$", srfile)
    if runm:   # nghiệm của lần chạy thứ k (k != 1): so với đúng dòng run == k trong CSV tương ứng
        csvfile = srfile[:runm.start()] + ".csv"
        if not os.path.exists(csvfile):
            return None
        for r in csv.DictReader(open(csvfile)):
            if r.get("run") == runm.group(1):
                try:
                    return float(r["mlu"])
                except (KeyError, ValueError):
                    return None
        return None
    csvfile = srfile.replace("-srpaths.json", ".csv")
    if base.startswith("heuristic-"):
        name = re.match(r"heuristic-(setA-\d+)-P(\d)", base)
        f = os.path.join(RES, f"heuristic-P{name.group(2)}.csv")
        for r in csv.DictReader(open(f)):
            if r["instance"] == name.group(1):
                return float(r["mlu"])
        return None
    if not os.path.exists(csvfile):
        return None
    rows = list(csv.DictReader(open(csvfile)))
    for r in rows:
        try:
            return float(r["mlu"])
        except (KeyError, ValueError):
            continue
    return None


def main():
    pat = sys.argv[1] if len(sys.argv) > 1 else ""
    files = sorted(glob.glob(os.path.join(RES, "*srpaths.json")))
    files = [f for f in files if pat in os.path.basename(f)]
    out = open(os.path.join(RES, "verification.csv"), "w", newline="")
    wr = csv.writer(out)
    wr.writerow(["file", "r_mode", "mlu_independent", "mlu_csv", "abs_diff", "mlu_tol1e-6", "tol_sensitive", "changes_t1", "problems"])
    worst, bad = 0.0, 0
    for f in files:
        m = re.search(r"(setA-\d+)(?:-wp)?-P(\d)", os.path.basename(f))
        name, P = m.group(1), int(m.group(2))
        mode = "pc" if "-pc-" in os.path.basename(f) else "ecmp"
        mlu, ch, pr = verify(name, P, f, 1e-9, mode)
        mlu2, _, _ = verify(name, P, f, 1e-6, mode)
        ref = csv_mlu(f)
        diff = abs(mlu - ref) if ref is not None else float("nan")
        sens = abs(mlu - mlu2) > 1e-6
        if ref is not None and diff > 1e-6:
            pr.append(f"MLU differs from CSV by {diff:.2e}")
        if pr or sens:
            bad += 1
        if ref is not None:
            worst = max(worst, diff)
        wr.writerow([os.path.basename(f), mode, f"{mlu:.10g}", ref, f"{diff:.2e}", f"{mlu2:.10g}", sens, ch.get(1, ""), "; ".join(pr[:3])])
        print(f"{os.path.basename(f):45s} mlu={mlu:.8f} csv={ref} diff={diff:.1e} tol_sens={sens} problems={len(pr)}", flush=True)
    out.close()
    print(f"checked {len(files)} files; with problems or tolerance sensitivity: {bad}; max |MLU - CSV| = {worst:.2e}")


if __name__ == "__main__":
    main()
