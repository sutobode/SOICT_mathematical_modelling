"""Vẽ hình tóm tắt CÁCH code giải bài toán và KẾT QUẢ thu được (đợt chạy chính thức trên server 24/10/2026, nhánh `kien`).

Số liệu lấy từ `BAO_CAO_KET_QUA_2026-10-24/BAO_CAO.md` và `report/chart_*.csv` (nhánh `kien`); được chép thành hằng số bên dưới để script
chạy được trên mọi nhánh.  Chạy: python orange/scripts/draw_results_figures.py  ->  project/figures/ket_qua/*.png  (cần matplotlib).
"""
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = os.path.join(ROOT, "project", "figures", "ket_qua")
os.makedirs(OUT, exist_ok=True)
OR, BL, GR, RD, GY = "#ff7900", "#1f5fbf", "#2e8b57", "#d62728", "#8a8a8a"

# (instance, mô hình, baseline, tối ưu/tốt nhất, đã chứng minh tối ưu?)
P1 = [("01", "full", 1.0000007, 0.9293839, True), ("02", "full", 1.0, 0.5485780, True), ("03", "full", 1.0000012, 0.9435434, True),
      ("04", "full", 0.6918, 0.5182800, False), ("05", "full", 0.3333, 0.1155237, True), ("10", "thu gọn", 1.0, 0.0711900, False)]
P2 = [("01", "full", 1.0, 0.9293839, True), ("02", "full", 1.0981, 0.9030747, True), ("03", "full", 1.0, 0.9435434, True),
      ("04", "full", 1.0, 0.5885700, False), ("05", "full", 0.99999, 0.2049859, True), ("07", "thu gọn", 1.0, 0.9079800, False)]
RUNTIME = [("01", 0.7, 20.8), ("02", 3.7, 2234.9), ("03", 32.0, 759.6), ("04", 1800.0, 3601.0), ("05", 149.0, 1880.0)]   # TB P1, TB P2 (s)


def save(fig, name, **kw):
    fig.savefig(os.path.join(OUT, name), dpi=140, **kw)
    plt.close(fig)


# ---------------------------------------------------------------- k1: MLU trước và sau
from matplotlib.patches import Patch

fig, axs = plt.subplots(1, 2, figsize=(13.5, 5.6))
for ax, data, ttl in [(axs[0], P1, "P1: chỉ t=0 (giới hạn 1800 s)"), (axs[1], P2, "P2: t=0 và t=1, cung bị tắt, có ngân sách (3600 s)")]:
    xs = range(len(data))
    ax.bar([i - 0.2 for i in xs], [d[2] for d in data], 0.4, color="#c9c9c9")
    for i, d in zip(xs, data):
        col = GR if d[4] else (BL if d[1] == "full" else RD)
        ax.bar(i + 0.2, d[3], 0.4, color=col)
        ax.text(i + 0.2, d[3] + 0.015, f"{d[3]:.3f}", ha="center", fontsize=8.5)
    ax.set_xticks(list(xs))
    ax.set_xticklabels([f"setA-{d[0]}\n−{(1 - d[3] / d[2]) * 100:.0f}%" + ("\n(thu gọn)" if d[1] != "full" else "") for d in data], fontsize=8.8)
    ax.set_ylim(0, 1.2)
    ax.set_ylabel("MLU (tải của cung nặng nhất)")
    ax.set_title(ttl, fontsize=10.5)
fig.legend(handles=[Patch(color="#c9c9c9", label="baseline: mọi nhu cầu đi thẳng"), Patch(color=GR, label="đã CHỨNG MINH tối ưu (mô hình đầy đủ)"),
                    Patch(color=BL, label="nghiệm hợp lệ, chưa chứng minh tối ưu (mô hình đầy đủ)"),
                    Patch(color=RD, label="mô hình thu gọn: chỉ là cận trên")], loc="lower center", ncol=4, fontsize=8.8, frameon=False)
fig.suptitle("Hình K1 — Kết quả chính thức: MLU của baseline và của nghiệm code tìm được (số % dưới tên instance = mức giảm so với baseline)", fontsize=11.5)
fig.tight_layout(rect=[0, 0.07, 1, 0.94])
save(fig, "k1_mlu_truoc_sau.png")

# ---------------------------------------------------------------- k2: cách code giải bài toán
fig, ax = plt.subplots(figsize=(13.8, 6.6))
ax.axis("off")
ax.set_xlim(0, 13.8)
ax.set_ylim(0, 6.6)
ax.text(0.1, 6.5, "Hình K2 — Code (orange/) giải bài toán thế nào: từ 3 file JSON đến nghiệm đã kiểm chứng", fontsize=12.5, fontweight="bold", va="top")


def box(x, y, w, h, t, fc, ls="-"):
    ax.add_patch(plt.Rectangle((x, y), w, h, fc=fc, ec="black", lw=1.1, ls=ls))
    ax.text(x + w / 2, y + h / 2, t, ha="center", va="center", fontsize=8.5)


def arr(x1, y1, x2, y2, c="black"):
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2), arrowstyle="-|>", mutation_scale=12, lw=1.3, color=c))


box(0.1, 4.4, 2.4, 1.4, "ĐỌC DỮ LIỆU\nio.jl: read_instance\nnet / tm / scenario\n→ n, m, c, ν, maxSeg,\nκ, cung tắt", "#fff2dd")
box(2.9, 4.4, 2.5, 1.4, "HỆ SỐ TÁCH r\necmp.jl: build_r\nchế độ :pathcount\n(calculating_r.pdf)\nvà :ecmp (đối chiếu)", "#e5f1ff")
box(5.8, 4.4, 2.6, 1.4, "NGHIỆM KHỞI ĐẦU\nheuristic.jl: local_search\ntìm kiếm cục bộ quanh\ncung nghẽn nhất, 30 s\n(mới: đổi mọi thời kỳ cùng lúc)", "#e6f6e6")
box(8.8, 4.4, 2.7, 1.4, "MÔ HÌNH MILP ĐẦY ĐỦ\nmodel.jl: build_model\nbiến x nhị phân, ràng buộc\n(1)–(4), min z (MLU thuần)\nHiGHS, khởi động nóng", "#ffe0b5")
box(11.9, 4.4, 1.8, 1.4, "GIẢI\noptimize!\n1 luồng, gap 1e-6\n1800 s hoặc\n3600 s", "#f3e9ff")
for x1, x2 in [(2.5, 2.9), (5.4, 5.8), (8.4, 8.8), (11.5, 11.9)]:
    arr(x1, 5.1, x2, 5.1)
box(8.8, 2.3, 2.7, 1.4, "TRÍCH NGHIỆM\nextract_paths\n→ dãy waypoint cho mỗi\n(nhu cầu, thời điểm)", "#e6f6e6")
box(5.8, 2.3, 2.6, 1.4, "KIỂM TRA TRONG CODE\nverify.jl: check_solution\ntính lại tải, số đoạn,\nngân sách; ghi srpaths.json", "#e5f1ff")
box(2.9, 2.3, 2.5, 1.4, "KIỂM CHỨNG ĐỘC LẬP\nverify_srpaths.py\n(Python, không dùng chung\ncode với Julia)", "#fff7c9")
box(0.1, 2.3, 2.4, 1.4, "BẢNG VÀ BÁO CÁO\nofficial_tables.jl,\nreporting.jl:\nBảng 1, Bảng 2", "#f3e9ff")
arr(12.2, 4.4, 11.5, 3.7)
arr(8.8, 3.0, 8.4, 3.0)
arr(5.8, 3.0, 5.4, 3.0)
arr(2.9, 3.0, 2.5, 3.0)
box(7.0, 0.3, 6.6, 1.3, "NHÁNH CHO INSTANCE QUÁ LỚN (setA-06…20)\nwpmodel.jl: mô hình waypoint, ≤ 1 waypoint / nhu cầu\n+ sinh cột (colgen) + LNS (lns.jl)\n→ chỉ cho CẬN TRÊN của bài toán gốc", "#fde2e2", ls="--")
box(0.1, 0.3, 6.5, 1.3, "THÍ NGHIỆM CẢI TIẾN (improvement_results_2026-10-24/)\n• bổ đề 'hai đường khác nhau lệch ≥ 3 segment'\n   ⇒ mô hình gộp biến khi κ < 3\n• chặn dưới theo nút cổ chai (setA-05) • thử lexicographic", "#e8f7ff", ls="--")
arr(13.3, 1.6, 13.3, 4.4, c=RD)
ax.text(13.0, 3.0, "dùng khi |D|·n(n−1)\nquá lớn so với RAM", rotation=90, ha="center", va="center", fontsize=8, color=RD)
save(fig, "k2_code_giai_the_nao.png", bbox_inches="tight")

# ---------------------------------------------------------------- k3: thời gian P1 và P2
fig, ax = plt.subplots(figsize=(9.5, 4.6))
xs = range(len(RUNTIME))
ax.bar([i - 0.2 for i in xs], [r[1] for r in RUNTIME], 0.4, color=OR, label="P1 (t=0), trung bình")
ax.bar([i + 0.2 for i in xs], [r[2] for r in RUNTIME], 0.4, color=BL, label="P2 (t=0,1), trung bình")
ax.set_yscale("log")
ax.axhline(1800, color=OR, ls=":", lw=1)
ax.axhline(3600, color=BL, ls=":", lw=1)
ax.text(4.55, 1800 * 1.12, "giới hạn P1 1800 s", fontsize=8, ha="right", color=OR)
ax.text(4.55, 3600 * 1.12, "giới hạn P2 3600 s", fontsize=8, ha="right", color=BL)
for i, r in zip(xs, RUNTIME):
    ax.text(i - 0.2, r[1] * 1.15, f"{r[1]:g}", ha="center", fontsize=8)
    ax.text(i + 0.2, r[2] * 1.15, f"{r[2]:.0f}", ha="center", fontsize=8)
ax.set_xticks(list(xs))
ax.set_xticklabels([f"setA-{r[0]}" for r in RUNTIME])
ax.set_ylabel("thời gian giải trung bình (s), thang log")
ax.set_title("Hình K3 — Hai thời kỳ (P2) khó hơn một thời kỳ (P1) nhiều lần; setA-04 chạm giới hạn ở cả hai", fontsize=10.5)
ax.legend(fontsize=8.5, loc="upper left")
fig.tight_layout()
save(fig, "k3_thoi_gian_p1_p2.png")

# ---------------------------------------------------------------- k4: setA-05 P2 — nút cổ chai
fig, axs = plt.subplots(1, 2, figsize=(13, 4.8), gridspec_kw={"width_ratios": [1, 1.25]})
ax = axs[0]
labels = ["baseline\n(đi thẳng)", "MILP lúc đầu\n(10 lần đều kẹt)", "sau khi sửa\nheuristic", "cận dưới\nchứng minh"]
vals = [0.99999, 0.99999, 0.2049859, 0.2049859]
cols = ["#c9c9c9", RD, GR, BL]
ax.bar(range(4), vals, color=cols)
for i, v in enumerate(vals):
    ax.text(i, v + 0.02, f"{v:.5f}", ha="center", fontsize=9)
ax.set_xticks(range(4))
ax.set_xticklabels(labels, fontsize=8.5)
ax.set_ylim(0, 1.15)
ax.set_ylabel("MLU")
ax.set_title("setA-05, hai thời kỳ: từ 0,99999 xuống 0,20499 (giảm 79,5%)\nvà MLU này được chứng minh là tối ưu", fontsize=10)
ax = axs[1]
ax.axis("off")
ax.set_xlim(0, 10)
ax.set_ylim(0, 6)
ax.text(0.1, 5.85, "Vì sao 0,2049858… là tối ưu? Một nút cổ chai", fontsize=11, fontweight="bold", va="top")
ax.add_patch(plt.Circle((5.2, 3.0), 0.5, fc="#ffd9a8", ec="black", lw=1.4))
ax.text(5.2, 3.0, "nút 17", ha="center", va="center", fontsize=9.5, fontweight="bold")
for k, y in enumerate([4.2, 3.0, 1.8]):
    ax.add_patch(plt.Circle((1.2, y), 0.4, fc="#bfe5c7", ec="black", lw=1.2))
    ax.text(1.2, y, "…", ha="center", va="center", fontsize=11)
    ax.add_patch(FancyArrowPatch((1.6, y), (4.7, 3.0), arrowstyle="-|>", mutation_scale=12, lw=1.2, color=GY))
ax.text(1.2, 4.85, "các nhu cầu xuất phát\ntừ nút 17", ha="center", fontsize=8.8)
ax.add_patch(plt.Circle((9.0, 3.0), 0.45, fc="white", ec="black", lw=1.4))
ax.text(9.0, 3.0, "nút 14", ha="center", va="center", fontsize=9, fontweight="bold")
ax.add_patch(FancyArrowPatch((5.7, 3.0), (8.55, 3.0), arrowstyle="-|>", mutation_scale=16, lw=3, color=RD))
ax.text(7.1, 3.35, "link DUY NHẤT 17→14\ndung lượng 26,465", ha="center", fontsize=9, color=RD, fontweight="bold")
ax.text(0.1, 0.65, "Ở t=1 nút 17 chỉ còn MỘT link đi ra. Mọi lưu lượng xuất phát từ nút 17 (tổng 5,425)\nbuộc phải đi qua link đó, nên với MỌI cách chọn waypoint:\nMLU ≥ 5,425 / 26,465 = 0,2049858…   (nghiệm tìm được đạt đúng bằng cận này)", fontsize=9.2, va="center")
fig.suptitle("Hình K4 — Cải tiến lớn nhất: setA-05 với hai thời kỳ", fontsize=12)
fig.tight_layout(rect=[0, 0, 1, 0.93])
save(fig, "k4_setA05_P2_nut_co_chai.png")

# ---------------------------------------------------------------- k5: bổ đề ≥3 và model gộp biến
fig, axs = plt.subplots(1, 3, figsize=(15, 4.6), gridspec_kw={"width_ratios": [1.15, 1, 1]})
ax = axs[0]
ax.axis("off")
ax.set_xlim(0, 10)
ax.set_ylim(0, 6)
ax.text(0.1, 5.85, "Bổ đề: hai đường khác nhau\ncùng từ s đến t lệch ≥ 3 segment", fontsize=10.5, fontweight="bold", va="top")
for lab, y, segs in [("P  = ⟨s,t⟩", 4.0, ["(s,t)"]), ("P' = ⟨s,w,t⟩", 2.6, ["(s,w)", "(w,t)"])]:
    ax.text(0.1, y, lab, fontsize=10, va="center")
    for i, sgm in enumerate(segs):
        ax.text(3.6 + i * 2.3, y, sgm, ha="center", va="center", fontsize=10, bbox=dict(boxstyle="round,pad=0.3", fc="#ffe0b5" if y > 3 else "#cfe3ff", ec="black"))
ax.text(0.1, 1.3, "1 + 2 = 3 hộp chỉ có ở một bên ⇒ dist = 3.\nHệ quả: số nhu cầu được đổi đường ≤ ⌊κ/3⌋;\nκ < 3 ⇒ KHÔNG nhu cầu nào được đổi đường.", fontsize=9.3, va="center")
names = ["setA-01", "setA-02", "setA-03"]
axs[1].bar([i - 0.2 for i in range(3)], [45601, 117451, 147001], 0.4, color=GY, label="mô hình gốc (hai thời kỳ)")
axs[1].bar([i + 0.2 for i in range(3)], [15201, 39151, 49001], 0.4, color=GR, label="mô hình gộp (1 bộ biến)")
axs[1].set_xticks(range(3))
axs[1].set_xticklabels(names)
axs[1].set_title("Số biến giảm 3 lần", fontsize=10.5)
axs[1].legend(fontsize=8)
t_orig, t_merge = [52.8, 900, 900], [3.9, 7.6, 60.6]
axs[2].bar([i - 0.2 for i in range(3)], t_orig, 0.4, color=GY, label="mô hình gốc")
axs[2].bar([i + 0.2 for i in range(3)], t_merge, 0.4, color=GR, label="mô hình gộp")
axs[2].set_yscale("log")
axs[2].set_xticks(range(3))
axs[2].set_xticklabels(names)
for i in range(3):
    axs[2].text(i - 0.2, t_orig[i] * 1.2, "TIME_LIMIT" if t_orig[i] >= 900 else f"{t_orig[i]}s", ha="center", fontsize=8, color=RD if t_orig[i] >= 900 else "black")
    axs[2].text(i + 0.2, t_merge[i] * 1.2, f"{t_merge[i]}s", ha="center", fontsize=8)
axs[2].set_title("Thời gian giải (κ=1, tối đa 900 s)", fontsize=10.5)
axs[2].set_ylim(top=4000)
axs[2].legend(fontsize=8, loc="upper left")
fig.suptitle("Hình K5 — Cải tiến toán học: khi ngân sách κ < 3, gộp biến mọi thời kỳ thành một bộ mà vẫn chính xác", fontsize=11.5)
fig.tight_layout(rect=[0, 0, 1, 0.92])
save(fig, "k5_bo_de_va_model_gop.png")
print("OK", sorted(os.listdir(OUT)))
