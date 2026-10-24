"""Vẽ hình minh hoạ bài toán T-ASR từ ví dụ toy của đề (số liệu tính lại bằng code, có assert với số của đề).
Chạy: python orange/scripts/draw_problem_figures.py  ->  project/figures/hinh_dung/*.png  (cần matplotlib)."""
import heapq
import json
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Circle

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = os.path.join(ROOT, "project", "figures", "hinh_dung")
os.makedirs(OUT, exist_ok=True)
net = json.load(open(os.path.join(ROOT, "orange", "test", "toy", "toy-net.json")))
tm = json.load(open(os.path.join(ROOT, "orange", "test", "toy", "toy-tm.json")))
sc = json.load(open(os.path.join(ROOT, "orange", "test", "toy", "toy-scenario.json")))
NAME = {n["id"]: f"v{n['id']}" for n in net["nodes"]}
ARCS = [(l["id"], l["from"], l["to"], l["metric"], l["capacity"]) for l in net["links"]]
DEM = [(d["s"], d["t"], d["v"]) for d in tm["demands"]]        # d0=(v0,v5)[50,100], d1=(v2,v5)[100,50]
DOWN1 = set(sc["interventions"][0]["links"])                   # ids 2,3 = a(1,3), a(1,4) tắt ở t=1
POS = {0: (1, 2), 1: (3, 2), 2: (0, 1), 4: (2, 1), 3: (4, 1), 6: (1, 0), 5: (3, 0)}
OR, BL, GR, RD, GY = "#ff7900", "#1f5fbf", "#2e8b57", "#d62728", "#888888"


# ---------------------------------------------------------------- tính toán
def dijkstra(src, down):
    dist = {n: float("inf") for n in NAME}
    dist[src] = 0
    pq = [(0, src)]
    while pq:
        d, u = heapq.heappop(pq)
        if d > dist[u]:
            continue
        for (aid, a, b, w, c) in ARCS:
            if a == u and aid not in down and d + w < dist[b] - 1e-12:
                dist[b] = d + w
                heapq.heappush(pq, (dist[b], b))
    return dist


def sigma(src, down, dist):
    order = sorted(NAME, key=lambda n: dist[n])
    s = {n: 0 for n in NAME}
    s[src] = 1
    for u in order:
        for (aid, a, b, w, c) in ARCS:
            if a == u and aid not in down and abs(dist[u] + w - dist[b]) < 1e-9:
                s[b] += s[u]
    return s


def split(u, v, down, mode):
    """r(u,v,.): {id cung: tỉ lệ}. mode = 'ecmp' (chia đều từng nút) hoặc 'count' (tỉ lệ số đường)."""
    du = dijkstra(u, down)
    if du[v] == float("inf"):
        return {}
    dd = {y: dijkstra(y, down) for y in NAME}
    fg = [(aid, a, b) for (aid, a, b, w, c) in ARCS
          if aid not in down and abs(du[a] + w - du[b]) < 1e-9 and abs(du[b] + dd[b][v] - du[v]) < 1e-9]
    r = {}
    if mode == "ecmp":
        flow = {n: 0.0 for n in NAME}
        flow[u] = 1.0
        for x in sorted(NAME, key=lambda n: du[n]):
            outs = [(aid, b) for (aid, a, b) in fg if a == x]
            for aid, b in outs:
                r[aid] = r.get(aid, 0) + flow[x] / len(outs)
                flow[b] += flow[x] / len(outs)
    else:
        su = sigma(u, down, du)
        sv = {y: sigma(y, down, dd[y]) for y in NAME}
        for (aid, a, b) in fg:
            r[aid] = su[a] * sv[b][v] / su[v]
    return r


def loads(paths, t, down, mode="ecmp"):
    """paths: {d: [s,w1,..,t]} -> {id cung: tải = luồng / dung lượng}."""
    cap = {aid: c for (aid, a, b, w, c) in ARCS}
    flow = {}
    for d, p in paths.items():
        vol = DEM[d][2][t]
        for u, v in zip(p, p[1:]):
            for aid, frac in split(u, v, down, mode).items():
                flow[aid] = flow.get(aid, 0) + frac * vol
    return {aid: f / cap[aid] for aid, f in flow.items()}


def route(s, t, w=()):
    return [s, *w, t]


triv = {0: route(0, 5), 1: route(2, 5)}
wayp = {0: route(0, 5, (4,)), 1: route(2, 5)}
L0 = loads(triv, 0, set())
L0w = loads(wayp, 0, set())
assert abs(max(L0.values()) - 0.4375) < 1e-9, max(L0.values())
assert abs(max(L0w.values()) - 0.375) < 1e-9, max(L0w.values())
a46 = [aid for (aid, a, b, w, c) in ARCS if (a, b) == (4, 6)][0]
assert abs(L0[a46] - 0.3125) < 1e-9

# ---------------------------------------------------------------- vẽ
ARC_OF = {aid: (a, b) for (aid, a, b, w, c) in ARCS}


def draw_net(ax, values=None, down=(), hi=(), title="", fmt="{:.2f}", node_col=None, show_wc=False, widthscale=6):
    ax.set_xlim(-0.6, 4.6)
    ax.set_ylim(-0.6, 2.6)
    ax.set_aspect("equal")
    ax.axis("off")
    values = values or {}
    for (aid, a, b, w, c) in ARCS:
        (x1, y1), (x2, y2) = POS[a], POS[b]
        rad = 0.16
        isdown = aid in down
        val = values.get(aid, 0)
        col = RD if isdown else (OR if val > 1e-9 else "#c8c8c8")
        lw = 0.8 if (val <= 1e-9 and not isdown) else 1.4 + widthscale * min(val, 1.0)
        if aid in hi:
            col = BL
        arr = FancyArrowPatch((x1, y1), (x2, y2), connectionstyle=f"arc3,rad={rad}", arrowstyle="-|>", mutation_scale=11,
                              lw=lw, color=col, linestyle="--" if isdown else "-", shrinkA=15, shrinkB=15, alpha=0.95)
        ax.add_patch(arr)
        mx, my = (x1 + x2) / 2, (y1 + y2) / 2
        dx, dy = x2 - x1, y2 - y1
        n = (dx * dx + dy * dy) ** 0.5
        ox, oy = dy / n * rad * n * 0.62, -dx / n * rad * n * 0.62       # đẩy nhãn lệch về phía cung cong
        if isdown:
            ax.text(mx + ox, my + oy, "✕", color=RD, ha="center", va="center", fontsize=11, fontweight="bold")
        elif val > 1e-9:
            ax.text(mx + ox, my + oy, fmt.format(val), ha="center", va="center", fontsize=8.5, color="black",
                    bbox=dict(boxstyle="round,pad=0.12", fc="white", ec=col, lw=0.8))
        elif show_wc:
            ax.text(mx + ox, my + oy, f"{w};{c}", ha="center", va="center", fontsize=6.5, color=GY)
    for n_, (x, y) in POS.items():
        fc = node_col.get(n_, "white") if node_col else "white"
        ax.add_patch(Circle((x, y), 0.17, fc=fc, ec="black", lw=1.2, zorder=5))
        ax.text(x, y, NAME[n_], ha="center", va="center", fontsize=9, zorder=6, fontweight="bold")
    if title:
        ax.set_title(title, fontsize=10.5)


NODE_COL = {0: "#bfe5c7", 2: "#bfe5c7", 5: "#ffd9a8"}     # xanh: nguồn; cam nhạt: đích

# ---- Hình 1: mạng + nhu cầu + nhãn ω;c
fig, ax = plt.subplots(figsize=(8.6, 5.2))
draw_net(ax, show_wc=True, node_col=NODE_COL, title="Hình 1 — Mạng toy: nút = router, mũi tên = liên kết 1 chiều; nhãn trên cung:  ω ; c  (trọng số ; dung lượng)")
ax.text(-0.55, 2.45, "● xanh: nguồn của nhu cầu (v0, v2)\n● cam: đích chung (v5)\nd0: v0→v5 (50 rồi 100)   d1: v2→v5 (100 rồi 50)", fontsize=9, va="top")
fig.tight_layout()
fig.savefig(os.path.join(OUT, "h1_mang_toy.png"), dpi=150)
plt.close(fig)

# ---- Hình 2: ECMP vs đếm đường cho nhu cầu (v0,v5)
r_e, r_c = split(0, 5, set(), "ecmp"), split(0, 5, set(), "count")
fig, axs = plt.subplots(1, 2, figsize=(12.5, 4.8))
draw_net(axs[0], r_e, node_col=NODE_COL, fmt="{:.2f}", title="ECMP chia đều TỪNG NÚT (đề, Bảng 2)\nở v1 chia 50-50, ở v4 chia 50-50 tiếp")
draw_net(axs[1], r_c, node_col=NODE_COL, fmt="{:.3f}", title="Tỉ lệ SỐ ĐƯỜNG (calculating_r.pdf)\n1/3 số đường qua a(1,3), 2/3 qua a(1,4)")
fig.suptitle("Hình 2 — Hệ số tách r(v0,v5,a,0): phần lưu lượng từ v0 đến v5 chảy qua mỗi cung (3 đường ngắn nhất bằng nhau)", fontsize=11)
fig.tight_layout(rect=[0, 0, 1, 0.92])
fig.savefig(os.path.join(OUT, "h2_ecmp_vs_dem_duong.png"), dpi=150)
plt.close(fig)

# ---- Hình 3: waypoint giảm tải lớn nhất
def sorted_bars(ax, L, title, ymax=0.5):
    items = sorted(L.items(), key=lambda kv: -kv[1])
    ax.bar(range(len(items)), [v for _, v in items], color=[BL if i == 0 else OR for i in range(len(items))])
    ax.set_ylim(0, ymax)
    ax.set_xticks(range(len(items)))
    ax.set_xticklabels([f"a{ARC_OF[k][0]},{ARC_OF[k][1]}" for k, _ in items], rotation=60, fontsize=7.5)
    ax.set_ylabel("tải λ(a,0)")
    ax.set_title(title, fontsize=10)
    ax.axhline(items[0][1], color=BL, lw=0.8, ls=":")


fig = plt.figure(figsize=(12.5, 8.4))
ga = fig.add_gridspec(2, 2, height_ratios=[1.25, 1])
a1, a2 = fig.add_subplot(ga[0, 0]), fig.add_subplot(ga[0, 1])
b1, b2 = fig.add_subplot(ga[1, 0]), fig.add_subplot(ga[1, 1])
hi0 = {max(L0, key=L0.get)}
hi1 = {max(L0w, key=L0w.get)}
draw_net(a1, L0, node_col=NODE_COL, hi=hi0, title="Không waypoint: d0 đi ⟨v0,v5⟩\ntải lớn nhất = 0,4375 (cung xanh đậm)")
draw_net(a2, L0w, node_col=NODE_COL, hi=hi1, title="Có waypoint v4 cho d0: đi ⟨v0,v4,v5⟩ (2 segment)\ntải lớn nhất = 0,3750")
sorted_bars(b1, L0, "Tải các cung, sắp giảm dần — không waypoint")
sorted_bars(b2, L0w, "Tải các cung, sắp giảm dần — có waypoint v4")
fig.suptitle("Hình 3 — Waypoint là 'điểm ghé buộc phải qua': đổi đường đi, hạ tải nghẽn nhất từ 0,4375 xuống 0,3750 (số trên cung = tải λ)", fontsize=11)
fig.tight_layout(rect=[0, 0, 1, 0.95])
fig.savefig(os.path.join(OUT, "h3_waypoint_giam_tai.png"), dpi=150)
plt.close(fig)

# ---- Hình 4: thời gian + cung bị tắt
L1 = loads(triv, 1, DOWN1)
fig, axs = plt.subplots(1, 2, figsize=(12.5, 4.8))
draw_net(axs[0], L0, node_col=NODE_COL, title="t = 0 (bình thường)\nmọi cung còn hoạt động")
draw_net(axs[1], L1, down=DOWN1, node_col=NODE_COL, title="t = 1 (bảo trì): a(1,3), a(1,4) bị TẮT (✕, nét đứt đỏ)\nlưu lượng của d0 buộc đi vòng; lưu lượng đổi: d0=100, d1=50")
fig.suptitle("Hình 4 — Thời gian: ở mỗi thời điểm lưu lượng ν(d,t) khác nhau, và ở t=1 một số cung bị tắt nên phải tính lại đường đi và hệ số r", fontsize=11)
fig.tight_layout(rect=[0, 0, 1, 0.92])
fig.savefig(os.path.join(OUT, "h4_thoi_gian_va_can_thiep.png"), dpi=150)
plt.close(fig)

# ---- Hình 5: biến x và khoảng cách dist (ngân sách)
def chips(ax, y, segs, color, label):
    ax.text(0.02, y, label, fontsize=10, va="center", fontweight="bold")
    for i, s in enumerate(segs):
        ax.text(0.34 + i * 0.16, y, f"({s[0]},{s[1]})", fontsize=10, va="center", ha="center",
                bbox=dict(boxstyle="round,pad=0.25", fc=color, ec="black", lw=0.8))


fig, ax = plt.subplots(figsize=(11.5, 5.4))
ax.axis("off")
ax.set_xlim(0, 1)
ax.set_ylim(0, 1)
ax.text(0.02, 0.96, "Hình 5 — Biến x và khoảng cách dist (đo ngân sách thay đổi)", fontsize=12, fontweight="bold", va="top")
ax.text(0.02, 0.88, "Mỗi hộp là một SEGMENT (i,j) của đường. x^{dt}_{ij} = 1 nếu đường của nhu cầu d tại thời điểm t chứa hộp (i,j).",
        fontsize=9.5, va="top")
rows = [
    ("⟨s,w,t⟩", [("s", "w"), ("w", "t")], "⟨s,t⟩", [("s", "t")], 3),
    ("⟨s,w1,w2,t⟩", [("s", "w1"), ("w1", "w2"), ("w2", "t")], "⟨s,w1,t⟩", [("s", "w1"), ("w1", "t")], 3),
    ("⟨s,w1,w2,t⟩", [("s", "w1"), ("w1", "w2"), ("w2", "t")], "⟨s,w2,w1,t⟩", [("s", "w2"), ("w2", "w1"), ("w1", "t")], 6),
    ("⟨s,w1,t⟩", [("s", "w1"), ("w1", "t")], "⟨s,w2,t⟩", [("s", "w2"), ("w2", "t")], 4),
]
for k, (n1, s1, n2, s2, dd) in enumerate(rows):
    y = 0.72 - k * 0.17
    chips(ax, y + 0.045, s1, "#ffe0b5", f"P  = {n1}")
    chips(ax, y - 0.045, s2, "#cfe3ff", f"P' = {n2}")
    diff = len(set(s1) ^ set(s2))
    assert diff == dd, (diff, dd)
    ax.text(0.97, y, f"dist = số hộp chỉ có ở MỘT bên = {dd}", fontsize=10.5, ha="right", va="center", color=RD, fontweight="bold")
ax.text(0.02, 0.05, "Ràng buộc ngân sách (4):  tổng dist giữa t-1 và t trên MỌI nhu cầu  ≤  κ(t).   Ví dụ κ(1)=1 nghĩa là chỉ được đổi đúng 1 segment.",
        fontsize=9.5, va="center")
fig.savefig(os.path.join(OUT, "h5_bien_x_va_dist.png"), dpi=150, bbox_inches="tight")
plt.close(fig)

# ---- Hình 6: sơ đồ tổng quan
fig, ax = plt.subplots(figsize=(12.5, 5.6))
ax.axis("off")
ax.set_xlim(0, 12.5)
ax.set_ylim(0, 5.6)


def box(x, y, w, h, text, fc):
    ax.add_patch(plt.Rectangle((x, y), w, h, fc=fc, ec="black", lw=1.1, zorder=2))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=9.3, zorder=3)


def arrow(x1, y1, x2, y2):
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2), arrowstyle="-|>", mutation_scale=14, lw=1.4, color="black", zorder=1))


ax.text(0.1, 5.45, "Hình 6 — Toàn cảnh bài toán T-ASR: đầu vào → cái ta CHỌN → cái ta ĐO → mục tiêu", fontsize=12, fontweight="bold", va="top")
box(0.1, 3.5, 3.0, 1.55, "ĐẦU VÀO (3 file JSON)\n• net: nút, cung, ω (trọng số), c (dung lượng)\n• tm: nhu cầu d=(s,τ), lưu lượng ν(d,t)\n• scenario: maxSeg, ngân sách κ(t),\n  cung bị tắt q(t)", "#fff2dd")
box(4.1, 3.5, 3.0, 1.55, "TÍNH TRƯỚC (cố định)\nhệ số tách r(i,j,a,t):\nsegment (i,j) đẩy bao nhiêu\nlưu lượng qua cung a\n(xét trên G_t đã bỏ cung tắt)", "#e5f1ff")
box(8.1, 3.5, 4.2, 1.55, "CÁI TA CHỌN (biến nhị phân)\nx^{dt}_{ij} ∈ {0,1}: nhu cầu d tại thời điểm t\ncó dùng segment (i,j) không\n= chọn dãy WAYPOINT cho mỗi nhu cầu,\nmỗi thời điểm", "#e6f6e6")
arrow(3.1, 4.25, 4.1, 4.25)
arrow(7.1, 4.25, 8.1, 4.25)
box(0.1, 1.1, 3.9, 1.7, "RÀNG BUỘC\n(1) mỗi nhu cầu một đường nối nguồn→đích\n(2) tối đa maxSeg segment mỗi đường\n(3) tải mỗi cung = Σ r·ν·x / c(a)\n(4) đổi cấu hình giữa t-1 và t ≤ κ(t)", "#ffe5e5")
box(4.6, 1.1, 3.6, 1.7, "CÁI TA ĐO\ntải λ(a,t) của mọi cung ở mọi thời điểm\n→ gom thành tập L, sắp giảm dần\nλ'(1) ≥ λ'(2) ≥ λ'(3) ≥ …", "#f3e9ff")
box(8.7, 1.1, 3.6, 1.7, "MỤC TIÊU (từ điển)\nhạ λ'(1) (cung nặng nhất) trước,\nrồi λ'(2), rồi λ'(3), …\n= 'đều tải, tránh nghẽn'", "#fff7c9")
arrow(10.2, 3.5, 10.2, 2.8)
arrow(6.4, 3.5, 6.4, 2.8)
arrow(4.0, 1.95, 4.6, 1.95)
arrow(8.2, 1.95, 8.7, 1.95)
ax.text(0.1, 0.45, "ĐẦU RA: file srpaths.json  =  danh sách {d, t, w=[waypoint…]} cho mỗi nhu cầu và mỗi thời điểm.   Nếu không waypoint: đi thẳng theo đường ngắn nhất.",
        fontsize=9.5, va="center")
fig.savefig(os.path.join(OUT, "h6_toan_canh.png"), dpi=150, bbox_inches="tight")
plt.close(fig)
print("OK", sorted(os.listdir(OUT)))
print("tải lớn nhất trivial/waypoint:", round(max(L0.values()), 4), round(max(L0w.values()), 4))
print("pathcount trivial MLU:", round(max(loads(triv, 0, set(), "count").values()), 4))
