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


def draw_net(ax, values=None, down=(), hi=(), title="", fmt="{:.2f}", node_col=None, show_wc=False, widthscale=6, labels=True):
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
        elif val > 1e-9 and labels:
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


# ================================================================ HÌNH BỔ SUNG (h7..h14)
def aid_of(a, b):
    return [aid for (aid, x, y, w, c) in ARCS if (x, y) == (a, b)][0]


def path_arcs(nodes):
    return {aid_of(a, b): 1.0 for a, b in zip(nodes, nodes[1:])}


# ---- h7: đồ thị chuyển tiếp FG(v0,v5) = hợp của các đường ngắn nhất
P1, P2, P3 = [0, 1, 3, 5], [0, 1, 4, 6, 5], [0, 1, 4, 3, 5]
fig, axs = plt.subplots(1, 4, figsize=(17, 4.3))
for ax, (pp, ttl) in zip(axs[:3], [(P1, "đường ngắn nhất #1\nv0→v1→v3→v5 (100+200+100=400)"),
                                     (P2, "đường ngắn nhất #2\nv0→v1→v4→v6→v5 (100+100+100+100=400)"),
                                     (P3, "đường ngắn nhất #3\nv0→v1→v4→v3→v5 (100+100+100+100=400)")]):
    draw_net(ax, path_arcs(pp), node_col=NODE_COL, title=ttl, labels=False, widthscale=2)
union = {}
for pp in (P1, P2, P3):
    union.update(path_arcs(pp))
draw_net(axs[3], union, node_col=NODE_COL, title="FG(v0,v5) = hợp của 3 đường\n(các cung 'đáng đi' từ v0 đến v5)", labels=False, widthscale=2)
fig.suptitle("Hình 7 — Đồ thị chuyển tiếp FG(u,v): gom mọi cung nằm trên ÍT NHẤT MỘT đường ngắn nhất từ u đến v", fontsize=11.5)
fig.tight_layout(rect=[0, 0, 1, 0.9])
fig.savefig(os.path.join(OUT, "h7_do_thi_chuyen_tiep.png"), dpi=140)
plt.close(fig)

# ---- h8: đường segment <v0,v4,v5> = FG(v0,v4) rồi FG(v4,v5)
r04, r45 = split(0, 4, set(), "ecmp"), split(4, 5, set(), "ecmp")
flow_d0 = {}
for rr in (r04, r45):
    for k, v in rr.items():
        flow_d0[k] = flow_d0.get(k, 0) + v * 50
fig, axs = plt.subplots(1, 3, figsize=(15.5, 4.6))
draw_net(axs[0], r04, node_col={0: "#bfe5c7", 4: "#ffe9a8"}, fmt="{:.2f}", title="Segment 1: (v0, v4)\nFG(v0,v4) và hệ số r")
draw_net(axs[1], r45, node_col={4: "#ffe9a8", 5: "#ffd9a8"}, fmt="{:.2f}", title="Segment 2: (v4, v5)\nFG(v4,v5) và hệ số r (chia đều 2 ngả)")
draw_net(axs[2], flow_d0, node_col={0: "#bfe5c7", 4: "#ffe9a8", 5: "#ffd9a8"}, fmt="{:.1f}",
         title="Lưu lượng của d0 (ν=50) = r×50 cộng cả 2 segment")
fig.suptitle("Hình 8 — Đường segment ⟨v0, v4, v5⟩ (waypoint v4, màu vàng) gồm 2 segment; mỗi segment đi theo ECMP trên đồ thị chuyển tiếp của nó", fontsize=11.5)
fig.tight_layout(rect=[0, 0, 1, 0.9])
fig.savefig(os.path.join(OUT, "h8_duong_segment.png"), dpi=140)
plt.close(fig)

# ---- h9: bảo toàn luồng (1) trên "đồ thị segment"
fig, ax = plt.subplots(figsize=(11.5, 4.4))
ax.axis("off")
ax.set_xlim(0, 12)
ax.set_ylim(0, 4.6)
ax.text(0.1, 4.4, "Hình 9 — Ràng buộc (1): các segment được chọn (x=1) phải nối thành MỘT chuỗi từ nguồn s đến đích τ", fontsize=11.5, fontweight="bold", va="top")
nodes = {"s": (1.4, 2.4), "w": (6.0, 2.4), "τ": (10.6, 2.4), "u": (6.0, 0.7)}
for k, (x, y) in nodes.items():
    ax.add_patch(Circle((x, y), 0.34, fc={"s": "#bfe5c7", "τ": "#ffd9a8"}.get(k, "white"), ec="black", lw=1.3, zorder=5))
    ax.text(x, y, k, ha="center", va="center", fontsize=12, fontweight="bold", zorder=6)
def seg(a, b, txt, on, rad=0.0):
    (x1, y1), (x2, y2) = nodes[a], nodes[b]
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2), connectionstyle=f"arc3,rad={rad}", arrowstyle="-|>", mutation_scale=16,
                                 lw=3.2 if on else 1.1, color=OR if on else "#b0b0b0", linestyle="-" if on else "--", shrinkA=15, shrinkB=15))
    ax.text((x1 + x2) / 2, (y1 + y2) / 2 + (0.35 if rad == 0 else (0.62 if rad > 0 else -0.62)), txt, ha="center", fontsize=10.5,
            color="black" if on else GY, fontweight="bold" if on else "normal")
seg("s", "w", "x_sw = 1", True)
seg("w", "τ", "x_wτ = 1", True)
seg("s", "τ", "x_sτ = 0", False, rad=0.35)
seg("s", "u", "x_su = 0", False)
seg("u", "τ", "x_uτ = 0", False)
for k, txt in [("s", "ra − vào = 1 − 0 = +1"), ("w", "ra − vào = 1 − 1 = 0"), ("τ", "ra − vào = 0 − 1 = −1")]:
    x, y = nodes[k]
    ax.text(x, y + 0.95, txt, ha="center", fontsize=10, color=BL)
ax.text(6.0, 3.95, "đường được chọn: ⟨s, w, τ⟩  (waypoint w)", ha="center", fontsize=10.5, color=OR, fontweight="bold")
ax.text(0.1, 0.2, "Ý nghĩa: tại mỗi nút, (số segment chọn đi RA) − (số segment chọn đi VÀO) = +1 ở nguồn, −1 ở đích, 0 ở nút giữa  ⇒  các segment nối đuôi nhau thành đúng một đường.",
        fontsize=9.5, va="bottom")
fig.savefig(os.path.join(OUT, "h9_bao_toan_luong.png"), dpi=140, bbox_inches="tight")
plt.close(fig)

# ---- h10: cách tính tải một cung (ràng buộc (3) / công thức λ)
rd0 = split(0, 5, set(), "ecmp")[a46]
rd1 = split(2, 5, set(), "ecmp")[a46]
assert abs(rd0 - 0.25) < 1e-9 and abs(rd1 - 0.5) < 1e-9
c46 = [c for (aid, a, b, w, c) in ARCS if aid == a46][0]
fig, ax = plt.subplots(figsize=(11.5, 4.7))
ax.axis("off")
ax.set_xlim(0, 12)
ax.set_ylim(0, 5)
ax.text(0.1, 4.85, "Hình 10 — Cách tính tải của MỘT cung: λ(a,t) = Σ r · ν · δ / c(a)   (ví dụ cung a(4,6), t=0, không waypoint)", fontsize=11.5, fontweight="bold", va="top")
scale = 9.0 / c46
x0, y0 = 1.5, 2.6
ax.add_patch(plt.Rectangle((x0, y0), c46 * scale, 0.7, fc="#f2f2f2", ec="black", lw=1.4))
ax.add_patch(plt.Rectangle((x0, y0), rd0 * 50 * scale, 0.7, fc=OR, ec="black", lw=1.0))
ax.add_patch(plt.Rectangle((x0 + rd0 * 50 * scale, y0), rd1 * 100 * scale, 0.7, fc=BL, ec="black", lw=1.0))
ax.annotate(f"d0: {rd0}×50 = {rd0*50}", xy=(x0 + rd0 * 50 * scale / 2, y0), xytext=(x0 + 0.6, y0 - 0.5), fontsize=9.5, color=OR, fontweight="bold", arrowprops=dict(arrowstyle="-|>", color=OR, lw=1.4))
ax.text(x0 + rd0 * 50 * scale + rd1 * 100 * scale / 2, y0 + 0.35, f"d1: {rd1}×100 = {rd1*100}", ha="center", va="center", fontsize=9.5, color="white", fontweight="bold")
ax.text(x0, y0 + 0.95, "← khung xám = dung lượng c(a) = 200 →", fontsize=9.5)
ax.text(x0 + c46 * scale, y0 - 0.2, f"c = {c46:.0f}", ha="right", fontsize=9.5)
ax.text(0.1, 1.7, f"Luồng qua cung  =  r(v0,v5,a,0)·ν(d0,0) + r(v2,v5,a,0)·ν(d1,0)  =  {rd0}·50 + {rd1}·100  =  {rd0*50 + rd1*100}", fontsize=11)
ax.text(0.1, 1.1, f"Tải  λ(a(4,6),0)  =  {rd0*50 + rd1*100} / {c46:.0f}  =  {(rd0*50 + rd1*100)/c46:.4f}    (khớp đề: 0,3125)", fontsize=11.5, color=RD, fontweight="bold")
ax.text(0.1, 0.35, "r = bao nhiêu phần lưu lượng của segment đẩy qua cung này;  ν = lưu lượng của nhu cầu;  δ = 1 nếu nhu cầu thật sự dùng segment đó (với đường không waypoint: segment (s,τ)).",
        fontsize=9, va="bottom")
fig.savefig(os.path.join(OUT, "h10_cach_tinh_tai.png"), dpi=140, bbox_inches="tight")
plt.close(fig)

# ---- h11: mục tiêu từ điển
fig, axs = plt.subplots(1, 2, figsize=(13, 4.8))
va = sorted(L0.values(), reverse=True)[:6]
vb = sorted(L0w.values(), reverse=True)[:6]
k = range(6)
axs[0].bar([i - 0.2 for i in k], va, 0.4, color=GY, label="A: không waypoint")
axs[0].bar([i + 0.2 for i in k], vb, 0.4, color=OR, label="B: có waypoint v4")
axs[0].set_xticks(list(k))
axs[0].set_xticklabels([f"hạng {i+1}" for i in k], fontsize=8.5)
axs[0].set_title("Số thật (toy): hạng 1 đã khác nhau\n0,4375 > 0,375  ⇒  B tốt hơn, dừng so sánh", fontsize=10)
axs[0].legend(fontsize=8.5)
axs[0].set_ylabel("tải sắp giảm dần")
A = [0.40, 0.40, 0.10, 0.10]
B = [0.40, 0.30, 0.30, 0.10]
axs[1].bar([i - 0.2 for i in range(4)], A, 0.4, color=GY, label="A = (0,40; 0,40; 0,10; 0,10)")
axs[1].bar([i + 0.2 for i in range(4)], B, 0.4, color=OR, label="B = (0,40; 0,30; 0,30; 0,10)")
axs[1].set_xticks(range(4))
axs[1].set_xticklabels([f"hạng {i+1}" for i in range(4)], fontsize=8.5)
axs[1].set_title("Số GIẢ ĐỊNH để minh hoạ khi hạng 1 hoà\nhạng 1 bằng nhau (0,40) ⇒ xét hạng 2: 0,30 < 0,40 ⇒ B tốt hơn", fontsize=10)
axs[1].legend(fontsize=8.5)
fig.suptitle("Hình 11 — Cực tiểu TỪ ĐIỂN: so từng hạng từ cung nặng nhất; hạng nào khác nhau đầu tiên thì bên nhỏ hơn thắng", fontsize=11.5)
fig.tight_layout(rect=[0, 0, 1, 0.92])
fig.savefig(os.path.join(OUT, "h11_muc_tieu_tu_dien.png"), dpi=140)
plt.close(fig)

# ---- h12: thời gian, can thiệp, ngân sách
fig, ax = plt.subplots(figsize=(12.5, 4.7))
ax.axis("off")
ax.set_xlim(0, 12.5)
ax.set_ylim(0, 4.8)
ax.text(0.1, 4.65, "Hình 12 — Trục thời gian T = {0, 1, …, h−1}: sự cố q(t) và ngân sách κ(t) chỉ có từ t = 1 trở đi (T* = T \\ {0})", fontsize=11.5, fontweight="bold", va="top")
ax.add_patch(FancyArrowPatch((0.4, 1.2), (12.2, 1.2), arrowstyle="-|>", mutation_scale=18, lw=2))
for x, lab in [(1.8, "t = 0"), (6.2, "t = 1"), (10.6, "t = 2, …")]:
    ax.plot([x, x], [1.1, 1.3], color="black", lw=2)
    ax.text(x, 0.8, lab, ha="center", fontsize=11, fontweight="bold")
ax.add_patch(plt.Rectangle((0.6, 1.9), 2.4, 1.9, fc="#e6f6e6", ec="black"))
ax.text(1.8, 2.85, "Trạng thái bình thường\nG₀ = G (đủ mọi cung)\nkhông can thiệp\nngân sách = ∞\nsơ đồ P⁰", ha="center", va="center", fontsize=9.6)
ax.add_patch(plt.Rectangle((5.0, 1.9), 2.4, 1.9, fc="#ffe5e5", ec="black"))
ax.text(6.2, 2.85, "Có can thiệp q(1) ⊆ A\nG₁ = G bỏ các cung q(1)\nngân sách κ(1)\nsơ đồ P¹", ha="center", va="center", fontsize=9.6)
ax.add_patch(plt.Rectangle((9.4, 1.9), 2.4, 1.9, fc="#fff2dd", ec="black"))
ax.text(10.6, 2.85, "(nếu h > 2) tương tự:\nq(2), κ(2), P², …", ha="center", va="center", fontsize=9.6)
ax.add_patch(FancyArrowPatch((3.0, 2.85), (5.0, 2.85), arrowstyle="-|>", mutation_scale=16, lw=2, color=RD))
ax.text(4.0, 3.15, "dist(P⁰,P¹) ≤ κ(1)", ha="center", fontsize=10.5, color=RD, fontweight="bold")
ax.add_patch(FancyArrowPatch((7.4, 2.85), (9.4, 2.85), arrowstyle="-|>", mutation_scale=16, lw=2, color=RD))
ax.text(8.4, 3.15, "dist(P¹,P²) ≤ κ(2)", ha="center", fontsize=10.5, color=RD, fontweight="bold")
ax.text(0.1, 0.15, "SetA: h = 2, nghĩa là chỉ có t=0 và t=1; ở t=1 đúng 1 cung bị tắt; κ(1) từ 1 đến 90 tuỳ instance.", fontsize=10, va="bottom")
fig.savefig(os.path.join(OUT, "h12_thoi_gian_ngan_sach.png"), dpi=140, bbox_inches="tight")
plt.close(fig)

# ---- h13: quy mô SetA và khả năng nạp mô hình theo cung
NDM = [(20, 80, 40), (30, 150, 45), (50, 250, 20), (50, 250, 200), (100, 396, 100), (100, 500, 500), (100, 500, 800), (150, 654, 200),
       (150, 750, 200), (150, 966, 1000), (200, 1000, 400), (200, 898, 400), (200, 1000, 2000), (250, 1108, 600), (250, 1250, 600),
       (250, 1452, 4800), (300, 1270, 2000), (300, 1500, 2000), (300, 1998, 6000), (400, 2000, 6000)]
nx = [d * n * (n - 1) for (n, m, d) in NDM]
fig, ax = plt.subplots(figsize=(12.5, 5.0))
cols = [GR if v <= 1e6 else (OR if v <= 8e6 else RD) for v in nx]
ax.bar(range(1, 21), nx, color=cols)
ax.set_yscale("log")
ax.set_ylim(top=6e9)
ax.axhline(3e6, color="black", ls="--", lw=1)
ax.text(0.55, 3.6e6, "ngưỡng an toàn của nhóm (3 triệu biến / thời kỳ)", ha="left", fontsize=8.5)
ax.set_xticks(range(1, 21))
ax.set_xticklabels([f"{i:02d}" for i in range(1, 21)], fontsize=8.5)
ax.set_xlabel("instance setA-XX")
ax.set_ylabel("số biến nhị phân x mỗi thời kỳ\n|D|·n·(n−1)  (thang log)")
ax.set_title("Hình 13 — Quy mô SetA: từ ~15 nghìn biến (setA-01) đến gần 1 tỷ (setA-20). Xanh: mô hình đầy đủ nạp được; cam/đỏ: quá lớn", fontsize=10.5)
for i, v in enumerate(nx):
    ax.text(i + 1, v * 1.15, f"{v/1e6:.2f}M" if v >= 1e6 else f"{v/1e3:.0f}k", ha="center", fontsize=6.8, rotation=90)
fig.tight_layout()
fig.savefig(os.path.join(OUT, "h13_quy_mo_setA.png"), dpi=140)
plt.close(fig)

# ---- h14: các bước của thầy
fig, ax = plt.subplots(figsize=(13, 6.0))
ax.axis("off")
ax.set_xlim(0, 13)
ax.set_ylim(0, 6)
ax.text(0.1, 5.85, "Hình 14 — Yêu cầu của thầy: 9 bước dẫn tới 2 bảng kết quả và báo cáo ≤ 10 trang (hạn Chủ nhật 25/10)", fontsize=12, fontweight="bold", va="top")
def sbox(x, y, w, h, txt, fc):
    ax.add_patch(plt.Rectangle((x, y), w, h, fc=fc, ec="black", lw=1.1))
    ax.text(x + w / 2, y + h / 2, txt, ha="center", va="center", fontsize=8.8)
def sarrow(x1, y1, x2, y2):
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2), arrowstyle="-|>", mutation_scale=13, lw=1.3))
row1 = [("1. Đọc và hiểu đề", "#fff2dd"), ("2. Dựng đồ thị G\n(script Pluto)", "#fff2dd"), ("3. Tính r[i,j,a,0]\n(calculating_r.pdf)", "#e5f1ff"), ("4. Mục DATA: r, c(a),\nν(d,0), MaxSeg", "#e5f1ff")]
for i, (t_, fc) in enumerate(row1):
    sbox(0.2 + i * 3.2, 4.2, 2.8, 1.1, t_, fc)
    if i < 3:
        sarrow(3.0 + i * 3.2, 4.75, 3.4 + i * 3.2, 4.75)
sbox(0.2, 2.5, 2.8, 1.1, "5. Mô hình CHỈ t=0\n(không ngân sách)", "#e6f6e6")
sbox(3.4, 2.5, 2.8, 1.1, "6. Thực nghiệm SetA, t=0\ngiới hạn 1800 s", "#ffe0b5")
sbox(6.6, 2.5, 2.8, 1.1, "7. Đồ thị G₁ và tham số\nở t=1", "#e5f1ff")
sbox(9.8, 2.5, 3.0, 1.1, "8. Mô hình t=0,1\n+ ngân sách (4)", "#e6f6e6")
sarrow(1.6, 4.2, 1.6, 3.6)
sarrow(3.0, 3.05, 3.4, 3.05)
sarrow(6.2, 3.05, 6.6, 3.05)
sarrow(9.4, 3.05, 9.8, 3.05)
sbox(9.8, 0.9, 3.0, 1.1, "9. Thực nghiệm SetA, t=0,1\ngiới hạn 3600 s", "#ffe0b5")
sarrow(11.3, 2.5, 11.3, 2.0)
sbox(0.2, 0.9, 5.0, 1.1, "BẢNG 1 (bước 6) và BẢNG 2 (bước 9)\ncột: n, m, |D|, giá trị tốt nhất, CPU time (chỉ optimize!),\nstatus, gap = 1 − LB/UB, số nút B&B\nTRUNG BÌNH TRÊN 10 LẦN CHẠY", "#fff7c9")
sbox(5.6, 0.9, 3.7, 1.1, "BÁO CÁO ≤ 10 trang\nGiới thiệu | Mô hình toán\n(Data, biến, mục tiêu, ràng buộc) |\nThực nghiệm (môi trường, bảng)", "#f3e9ff")
sarrow(9.8, 1.45, 9.3, 1.45)
sarrow(5.6, 1.45, 5.2, 1.45)
ax.text(0.2, 0.35, "Bước 9 trong readme ghi nhầm 'only time period 0'; nhóm hiểu là hai thời điểm t=0,1 có ngân sách.", fontsize=9.5, va="center")
fig.savefig(os.path.join(OUT, "h14_cac_buoc_cua_thay.png"), dpi=140, bbox_inches="tight")
plt.close(fig)
print("extra OK", sorted(f for f in os.listdir(OUT) if f.startswith(("h7", "h8", "h9", "h10", "h11", "h12", "h13", "h14"))))
