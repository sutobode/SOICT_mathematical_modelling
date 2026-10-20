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
import math
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
    period_loads = {}
    base_loads = {}
    for t in range(P):
        load = {a: 0.0 for a in periods[t].arcs}
        base_load = {a: 0.0 for a in periods[t].arcs}
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
            for a, fr in periods[t].split(dd["s"], dd["t"]).items():
                base_load[a] += fr * dd["v"][t]
        period_loads[t] = load
        base_loads[t] = base_load
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
    return mlu, changes, problems, period_loads, base_loads


def verify_load_artifact(loadfile, expected_run, name, P, period_loads, base_loads, caps, mlu, tol=1e-6):
    """Use relative tolerance 1e-6 (plus 1e-12 absolute) for all load comparisons."""
    with open(loadfile, newline="") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames != ["kind", "rank", "period", "link_id", "base", "opt",
                                 "run", "instance", "P", "routing_mode"]:
            raise ValueError("load CSV is missing required columns")
        rows = list(reader)
    if not rows:
        raise ValueError("load CSV is empty")
    for row in rows:
        if (row["run"] != str(expected_run) or row["instance"] != name or
                row["P"] != str(P) or row["routing_mode"] != "pathcount"):
            raise ValueError("load CSV provenance does not match the selected run")

    expected_arc = {}
    for period, loads in period_loads.items():
        for link_id, value in loads.items():
            expected_arc[(period, link_id)] = value / caps[link_id]
    actual_arc = {}
    actual_sorted = {}
    actual_base = {}
    for row in rows:
        try:
            opt, base = float(row["opt"]), float(row["base"])
            if not (math.isfinite(opt) and math.isfinite(base)):
                raise ValueError("non-finite load value")
            if row["kind"] == "arc":
                key = (int(row["period"]), int(row["link_id"]))
                if key in actual_arc:
                    raise ValueError("duplicate physical arc/period row")
                actual_arc[key] = opt
            elif row["kind"] == "sorted":
                rank = int(row["rank"])
                if rank in actual_sorted:
                    raise ValueError("duplicate sorted-load rank")
                actual_sorted[rank] = opt
                actual_base[rank] = base
            else:
                raise ValueError("unknown load CSV row kind")
        except (TypeError, ValueError) as exc:
            raise ValueError("malformed load CSV row") from exc
    if set(actual_arc) != set(expected_arc):
        raise ValueError("load CSV physical arc/period rows do not match the instance")
    for key, value in expected_arc.items():
        if not isclose(actual_arc[key], value, tol):
            raise ValueError(f"load CSV utilization mismatch at period/link {key}")
    expected_sorted = sorted(expected_arc.values(), reverse=True)
    if set(actual_sorted) != set(range(1, len(expected_sorted) + 1)):
        raise ValueError("load CSV sorted vector has missing or unexpected ranks")
    if any(not isclose(actual_sorted[k + 1], value, tol)
           for k, value in enumerate(expected_sorted)):
        raise ValueError("load CSV sorted load vector is inconsistent")
    expected_base = sorted(
        [value / caps[link_id]
         for loads in base_loads.values()
         for link_id, value in loads.items()],
        reverse=True,
    )
    if set(actual_base) != set(range(1, len(expected_base) + 1)):
        raise ValueError("load CSV baseline vector has missing or unexpected ranks")
    if any(not isclose(actual_base[k + 1], value, tol)
           for k, value in enumerate(expected_base)):
        raise ValueError("load CSV baseline vector is inconsistent")
    if not isclose(expected_sorted[0], mlu, tol):
        raise ValueError("reported MLU differs from recomputed maximum utilization")


def csv_mlu(srfile):
    """MLU của lần chạy đầu trong CSV tương ứng với file srpaths."""
    base = os.path.basename(srfile)
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
    if len(sys.argv) >= 2 and sys.argv[1] == "--single":
        if len(sys.argv) != 9:
            print("usage: verify_srpaths.py --single <instance> <P> <srpaths> <ecmp|pathcount> <expected_mlu> <loads_csv> <run>")
            sys.exit(1)
        name, P, srfile, mode_arg, expected = sys.argv[2], int(sys.argv[3]), sys.argv[4], sys.argv[5], float(sys.argv[6])
        loadfile, expected_run = sys.argv[7], sys.argv[8]
        mode = "pc" if mode_arg == "pathcount" else "ecmp"
        mlu, _, problems, period_loads, base_loads = verify(name, P, srfile, 1e-9, mode)
        mlu2, _, problems2, _, _ = verify(name, P, srfile, 1e-6, mode)
        problems.extend(problems2)
        if not isclose(mlu, expected, 1e-6):
            problems.append(f"MLU differs from expected by {abs(mlu - expected):.2e}")
        if abs(mlu - mlu2) > 1e-6:
            problems.append("routing is tolerance-sensitive")
        try:
            net, _, _ = load_instance(name)
            caps = {link["id"]: float(link["capacity"]) for link in net["links"]}
            verify_load_artifact(loadfile, expected_run, name, P, period_loads, base_loads, caps, mlu)
        except (OSError, ValueError, KeyError, csv.Error) as exc:
            problems.append(f"load artifact verification failed: {exc}")
        print(json.dumps({"mlu": mlu, "expected": expected, "problems": problems}))
        sys.exit(0 if not problems else 2)
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
        mlu, ch, pr, _, _ = verify(name, P, f, 1e-9, mode)
        mlu2, _, _, _, _ = verify(name, P, f, 1e-6, mode)
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
