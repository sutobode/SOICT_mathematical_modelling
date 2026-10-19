# Project Orange — T-Adaptive Segment Routing: Phân tích đầy đủ

> **Tài liệu gốc:** `Challenge_Orange_ROADEF_2026_Subject.pdf` (đề), `calculating_r.pdf`, `readme`, cấu trúc `setA/`, và các script Pluto trong `project/`.
> **Đã kiểm chứng:** ví dụ "toy" của đề được tái tạo bằng code Python (xem mục 4).
> **Lưu ý quan trọng:** file này thay thế `PHAN_TICH_BAI_TOAN.md`. Phần cách tính r của file cũ là **sai** (xem mục 4).
> **Kiểm chứng:** xem mục 12 để biết điều gì đã được kiểm tra bằng dữ liệu thật và điều gì **chưa**.

---

## 0. Tóm tắt trong một trang

- **Bài toán:** với mạng có hướng $G=(V,A)$, các demand $(s,t)$ có lưu lượng theo 2 thời điểm, và một kịch bản cắt cung, hãy chọn cho mỗi demand một **đường segment** (dãy waypoint) sao cho **tải lớn nhất trên cung nhỏ nhất có thể**, đồng thời số thay đổi waypoint giữa hai thời điểm không vượt ngân sách.
- **Mô hình:** MILP với biến nhị phân $x^{dt}_{ij}$. Các ràng buộc tải và lưu lượng đều tuyến tính khi $r$ là hằng số.
- **Thứ quan trọng nhất cần nhớ:** hệ số tách $r$ phải tính theo **ECMP từng chặng** (chia đều luồng tại mỗi nút cho các cung ra trên đường ngắn nhất), **không** theo công thức đếm đường ngắn nhất trong `calculating_r.pdf`. Hai cách này cho kết quả khác nhau. Đề và ví dụ toy khớp với ECMP từng chặng.
- **Việc cần làm:** viết module đọc dữ liệu → tính $r$ (ECMP) → mô hình JuMP → chạy SetA ($t=0$ với 1800 s; $t=0,1$ với 3600 s) → báo cáo 10 trang, mỗi số liệu là trung bình 10 lần chạy.

---

## 1. Bối cảnh và động cơ

Orange quản lý mạng IP/MPLS lớn. Traffic Engineering (TE) nhằm tránh nghẽn để giữ chất lượng dịch vụ. Mạng phải hoạt động được khi một liên kết bị hỏng hoặc bị tắt có kế hoạch. Segment Routing (SR, RFC 8402) cho phép gói tin đi qua các waypoint, nên có thể đi đường không ngắn nhất mà không phải sửa nhiều mạng. Bài toán là thiết kế các đường SR này cho mọi demand, sao cho cân bằng tải ngay cả khi có cung bị tắt.

---

## 2. Khái niệm nền tảng

| Khái niệm | Nghĩa |
|---|---|
| **Cung (arc/link)** | Cạnh có hướng $a=(u,v)$. Có trọng số $\omega(a)$ (trong JSON: `metric`) và dung lượng $c(a)$ (`capacity`). |
| **Đường ngắn nhất theo $\omega$** | Đường có tổng $\omega$ nhỏ nhất. Có thể có nhiều đường bằng nhau. |
| **$FG(u,v)$ — đồ thị chuyển tiếp** | Tập các cung nằm trên ít nhất một đường ngắn nhất từ $u$ đến $v$. |
| **ECMP** | Khi $FG(u,v)$ không phải một đường đơn, tại mỗi nút luồng **chia đều** cho các cung ra thuộc $FG(u,v)$. |
| **$r(u,v,a,t)$** | Tỷ lệ luồng từ $u$ đến $v$ đi qua cung $a$ khi mạng ở trạng thái $G_t$. Bằng 0 nếu $a \notin FG(u,v)$. |
| **Đoạn (segment)** | Cặp nút liên tiếp $(i,j)$ trong dãy đường. Mỗi đoạn định tuyến theo ECMP trên $FG(i,j)$. |
| **Đường segment** | Dãy $s, w_1, \dots, w_l, t$. Các $w$ là waypoint, theo thứ tự. $l=0$ nghĩa là đi thẳng theo đường ngắn nhất. |
| **maxSeg** | Số đoạn tối đa của một đường. Trong SetA là 6. Đề đặt $\text{maxSeg} \ge 2$. |
| **Demand $d=(s_d,\tau_d)$** | Cặp nguồn–đích có lưu lượng $\delta(d,t)$. ID demand là **vị trí trong danh sách** (từ 0). |
| **$G_t$** | Đồ thị tại thời điểm $t$, chỉ gồm các cung $A \setminus q(t)$. |
| **$q(t)$ — kịch bản** | Tập cung bị tắt tại $t$. Đề chỉ xét cung bị tắt (nút bị tắt tương đương mọi cung của nút đó bị tắt). |
| **$\beta(t)$ — ngân sách** | Số thay đổi tối đa từ $t-1$ sang $t$. Tại $t=0$ ngân sách coi như vô hạn và không có cung bị tắt. |
| **$\text{dist}(P,P')$** | Số thay đổi giữa hai cấu hình, đếm số đoạn $(i,j)$ khác nhau trên mọi demand. |
| **Tải $U(a,t)$** | Luồng qua $a$ chia cho $c(a)$. Có thể $>1$ nếu nghẽn. |
| **MLU** | Max Link Utilization: tải lớn nhất trên mọi cung. |

**Ví dụ về dist (Bảng 1 của đề):** $\{s,w,t\} \to \{s,t\}$ có $\text{dist}=3$. $\{s,w_1,w_2,t\} \to \{s,w_2,w_1,t\}$ có $\text{dist}=6$.

---

## 3. Mô hình toán học

### 3.1. Tập hợp và tham số
- $V$ (nút, $n=\lvert V\rvert$), $A$ (cung, $m=\lvert A\rvert$), $D$ (demand), $T=\{0,\dots,h-1\}$, $T'=T\setminus\{0\}$.
- $\omega(a)$, $c(a)$, $\delta(d,t)$, $q(t)$, $\beta(t)$, $\text{maxSeg}$.
- $r(i,j,a,t)$ tính trên $G_t$ (xem mục 4).

### 3.2. Biến
- $x^{dt}_{ij} \in \{0,1\}$, với $d \in D$, $t \in T$, $i \in V$, $j \in V\setminus\{i\}$. Bằng 1 nếu đường của $d$ tại $t$ chứa đoạn $(i,j)$.
- $U(a,t) \ge 0$ — tải của cung $a$ tại $t$ (biến phụ, dùng cho mục tiêu).
- $z \ge 0$ — MLU (nếu dùng min MLU).
- $y^{dt}_{ij} \ge 0$ — biến phụ tuyến tính hóa $\lvert x^{dt}_{ij} - x^{d,t-1}_{ij}\rvert$ (chỉ cho $t \in T'$).

### 3.3. Ràng buộc (theo đề)

Ký hiệu đích của demand là $\tau_d$ để tránh nhầm với thời điểm $t$.

**(1) Bảo toàn luồng**, với mọi $d$, $t$, $i \in V$:

$$
\sum_{j \ne i} x^{dt}_{ij} - \sum_{j \ne i} x^{dt}_{ji} =
\begin{cases}
+1, & i = s_d \\
-1, & i = \tau_d \\
0, & \text{các trường hợp khác}
\end{cases}
$$

**(2) Giới hạn số đoạn**, với mọi $d$, $t$:

$$
\sum_{i,j \in V} x^{dt}_{ij} \le \text{maxSeg}
$$

**(3) Ràng buộc tải**, với mọi $t$, $a \in A \setminus q(t)$:

$$
\sum_{d \in D} \sum_{i,j \in V} r(i,j,a,t)\, \delta(d,t)\, x^{dt}_{ij} \;\le\; U(a,t)\, c(a)
$$

Lưu ý quan trọng: $r(\cdot,\cdot,\cdot,t)$ tính trên $G_t$. Đề không ghi rõ việc cấm đi qua cung bị tắt. Cần xử lý như sau: $r(i,j,a,t)=0$ nếu $a \in q(t)$, và $FG(i,j)$ được tính trên $G_t$. Khi đó không có luồng nào đi qua cung bị tắt. Đây là điểm cần ghi rõ trong báo cáo.

**(4) Ngân sách thay đổi**, với mọi $t \in T'$:

$$
\sum_{d \in D} \sum_{i \ne j} \left\lvert x^{dt}_{ij} - x^{d,t-1}_{ij} \right\rvert \;\le\; \beta(t)
$$

Tuyến tính hóa bằng biến $y$:

$$
y^{dt}_{ij} \ge x^{dt}_{ij} - x^{d,t-1}_{ij}, \qquad
y^{dt}_{ij} \ge x^{d,t-1}_{ij} - x^{dt}_{ij}, \qquad
\sum_{d,i,j} y^{dt}_{ij} \le \beta(t)
$$

**(7)** $x^{dt}_{ij} \in \{0,1\}$. **(8)** $U(a,t) \ge 0$.

### 3.4. Mục tiêu

Đề (5): **lexicographic min** của vector $U$ sắp giảm dần:

$$
\operatorname{lex\,min}\ \bigl\{\, U_{(i)} : 1 \le i \le \lvert L \rvert \,\bigr\}, \qquad L = \{\, U(a,t) : a \in A,\ t \in T \,\}
$$

với $U_{(i)}$ là phần tử thứ $i$ lớn nhất của $L$. Tức là tối thiểu tải lớn nhất, rồi đến tải lớn thứ hai, và cứ thế.

Trong MILP, lexicographic min không cài trực tiếp được. Hai cách thực tế:
- **Min MLU:** $\min z$ với $z \ge U(a,t)$ cho mọi $(a,t)$. Đây là cách đơn giản và đủ để báo cáo.
- **Lex nhiều bước:** giải min MLU, cố định $z^*$, rồi giải tiếp để tối thiểu tải thứ hai, v.v. Tốn thời gian gấp nhiều lần.

**Quyết định cần chốt:** dùng cách nào và ghi lý do trong báo cáo.

### 3.5. Đặc điểm mô hình
- Với $r$ cố định, mọi ràng buộc đều tuyến tính. Chỉ có $x$ là nhị phân.
- Số biến $x$: $\lvert D\rvert \cdot n(n-1)$. Số ràng buộc (3): khoảng $m \cdot \lvert T\rvert$.
- Số biến lớn: setA-01 có $40 \cdot 380 = 15\,200$ biến. setA-20 có $6000 \cdot 159\,600 \approx 9{,}6 \cdot 10^{8}$ biến, vượt xa khả năng MIP. Chỉ các instance nhỏ và vừa mới giải tối ưu được trong thời gian cho phép. Phải báo cáo trung thực các trường hợp Not Optimal.

---

## 4. Tính hệ số tách $r$ — phần quan trọng nhất

### 4.1. Định nghĩa đúng (theo đề)

Đề định nghĩa $r(u,v,a,t)$ là **tỷ lệ luồng** từ $u$ đến $v$ đi qua $a$, với luồng chia theo ECMP:
- Tại mỗi nút $x \in FG(u,v)$, luồng đến $x$ được chia đều cho các cung ra $(x,y)$ thuộc $FG(u,v)$.
- $r(u,v,a,t)$ là phần luồng đơn vị đi qua $a$.

Đây là định nghĩa dùng để tính tải. Nó được minh họa ở Figure 1 của đề.

### 4.2. Cảnh báo: `calculating_r.pdf` dùng định nghĩa khác

`calculating_r.pdf` tính

$$
r_{ijat} = \frac{\sigma_{iaj}(t)}{\sigma_{ij}(t)}
$$

trong đó $\sigma_{ij}(t)$ là số đường ngắn nhất từ $i$ đến $j$ và $\sigma_{iaj}(t)$ là số đường ngắn nhất đi qua $a$. Đây là **tỷ lệ số đường ngắn nhất đi qua $a$**, không phải phép chia luồng theo ECMP từng chặng. Hai cách cho kết quả khác nhau khi có nút rẽ nhiều nhánh.

**Ví dụ kiểm chứng từ toy:** đường đi $0 \to 5$ có 3 đường ngắn nhất cùng độ dài 400: $(0,1,3,5)$, $(0,1,4,6,5)$, $(0,1,4,3,5)$.
- Công thức đếm đường cho $r(0,5,(1,4)) = \dfrac{2}{3} \approx 0{,}667$.
- ECMP từng chặng (đề, Bảng 2) cho $r(0,5,(1,4)) = 0{,}5$.

Đề dùng $0{,}5$. **Kết luận:** dùng ECMP từng chặng. Công thức trong `calculating_r.pdf` không khớp với định nghĩa của đề.

### 4.3. Cách tính ECMP từng chặng

Với mỗi cặp $(u,v)$ cần thiết (đầu mút của demand hoặc waypoint khả dĩ), và mỗi thời điểm $t$ trên $G_t$:

1. Chạy Dijkstra từ $u$ trên $G_t$, lấy $\operatorname{dist}_u[\cdot]$ (theo $\omega$).
2. Xác định các nút $x$ thỏa $\operatorname{dist}_u[x] + \operatorname{dist}_x[v] = \operatorname{dist}_u[v]$ (nằm trên đường ngắn nhất). Cần $\operatorname{dist}_x[v]$, nên chạy Dijkstra từ mọi nguồn hoặc chạy ngược từ $v$.
3. Sắp xếp các nút này theo $\operatorname{dist}_u$ tăng dần (đây là thứ tự topo của DAG).
4. Gán luồng $f_u = 1$. Với mỗi nút $x$ theo thứ tự, lấy các cung ra $(x,y)$ thuộc $FG(u,v)$, tức là

$$
\operatorname{dist}_u[x] + \omega(x,y) = \operatorname{dist}_u[y] \quad \text{và} \quad \operatorname{dist}_u[y] + \operatorname{dist}_y[v] = \operatorname{dist}_u[v]
$$

Chia đều luồng của $x$ cho các cung này:

$$
r(u,v,(x,y),t) \mathrel{+}= \frac{f_x}{\lvert \mathrm{Out}_{FG}(x) \rvert}, \qquad f_y \mathrel{+}= \frac{f_x}{\lvert \mathrm{Out}_{FG}(x) \rvert}
$$

trong đó $\mathrm{Out}_{FG}(x)$ là tập các cung ra của $x$ thuộc $FG(u,v)$.

Chi tiết cài đặt: các phép so sánh khoảng cách ở bước 2 và 4 là so sánh **bằng nhau**. Với instance có metric nguyên thì chính xác. Với instance 05, 08, 12, 14 (metric thực) phải dùng **dung sai** (ví dụ `isapprox` với `rtol≈1e-9`), nếu không thì các đường bằng nhau có thể bị coi là khác nhau do sai số cộng dồn, làm $FG(u,v)$ và $r$ sai. Cũng cần thận trọng nếu dùng `allpaths=true` của Graphs.jl với metric thực.

### 4.4. Kiểm chứng đã thực hiện

Đã viết script Python (chạy bằng `python -I`) mô phỏng ECMP từng chặng trên ví dụ toy. Kết quả khớp đúng với đề:

| Đại lượng | Đề | Tính lại |
|---|---|---|
| $r(v_0,v_5,a_{1,4},0)$ | 0.5 | 0.5 |
| $r(v_0,v_5,a_{4,6},0)$ | 0.25 | 0.25 |
| $\mathrm{load}(a_{4,6},0)$ | 0.3125 | 0.3125 |
| MLU, không waypoint, $t=0$ | 0.4375 | 0.4375 |
| MLU, waypoint $v_4$ cho $d_0$, $t=0$ | 0.3750 | 0.3750 |

Cách đếm đường (`calculating_r.pdf`) cho $r(v_0,v_5,a_{1,4},0) = 0{,}667$ và MLU $= 0{,}4167$, nên không khớp.

**Khuyến nghị:** dùng ECMP từng chặng để kiểm tra tất cả các số trong báo cáo. Đây là bài kiểm thử đơn vị bắt buộc trước khi chạy SetA.

### 4.5. Tính $r$ cho $t=1$
Chạy lại toàn bộ quy trình trên $G_1$ = $G$ với $A \setminus q(1)$ bị loại bỏ. Ví dụ trong đề: cung $a_{1,3}$ và $a_{1,4}$ bị tắt tại $t=1$, nên mọi luồng phải đi qua đường khác.

---

## 5. Dữ liệu

### 5.1. Ba file đầu vào

**(a) `net.json`** — định dạng NetworkX.
```
directed: true; multigraph: false
nodes: [{name, id}]              → V, tên nút
links: [{id, from, to, metric, capacity}] → A, ω(a)=metric, c(a)=capacity
```
- `id` của nút có thể bắt đầu từ 0. Ánh xạ sang chỉ số $1..n$ (notebook Pluto làm điều này: `id_to_vertex`).
- `id` của cung là khóa dùng trong `interventions`. Ánh xạ id → chỉ số cung.
- **Cờ `multigraph` không đáng tin.** 10/20 instance (05, 06, 08, 10, 12, 13, 14, 16, 17, 19) khai báo `multigraph: true` và có thêm khóa `graph: {}`, nhưng đã kiểm tra: **không instance nào có cung song song hay khuyên** (mọi cặp $(from,to)$ đều duy nhất). Notebook `json_to_graph_pluto_v2.jl` sẽ **báo lỗi** với 10 instance này vì nó từ chối `multigraph=true`. Cách xử lý: tự đọc JSON, bỏ qua cờ này, và tự kiểm tra cung song song trong code.

**(b) `tm.json`** — ma trận lưu lượng.
```
num_time_slots: 2
demands: [{v: [v_0, v_1], s, t}]   → δ(d,τ)=v[τ+1], demand d = vị trí trong mảng
```
- Kiểm tra trên setA-01: 40 demand, không có demand nào có $s = t$, và không có cặp $(s,t)$ trùng.

**(c) `scenario.json`**
```
max_segments: maxSeg
budget: [{t, value}]               → β(t)
interventions: [{t, links:[id,...]}] → q(t), theo id cung
```
- Thời điểm 0 không xuất hiện trong file: ngân sách vô hạn và không có cung bị tắt.
- Trong SetA chỉ có $t=1$.

### 5.2. Bảng tham số

| Ký hiệu | Nguồn | Ghi chú |
|---|---|---|
| $V$, $n$ | net `nodes` | |
| $A$, $m$ | net `links` | |
| $\omega(a)$ | `metric` | **không phải lúc nào cũng nguyên**: instance 05, 08, 12, 14 có metric thực trong khoảng $0{,}001$–$1{,}2$; các instance khác là số nguyên (100–110649) |
| $c(a)$ | `capacity` | |
| $D$, $(s_d, \tau_d)$ | tm `demands` | ID demand = vị trí |
| $\delta(d,0)$, $\delta(d,1)$ | tm `v` | |
| $q(t)$ | scenario `interventions` | theo id cung |
| $\beta(t)$ | scenario `budget` | chỉ $t=1$ |
| $\text{maxSeg}$ | scenario `max_segments` | $=6$ |
| $r(\cdot,\cdot,\cdot,0)$, $r(\cdot,\cdot,\cdot,1)$ | tính theo mục 4 | |

### 5.3. Quy mô SetA

| Inst | Nút | Cung | Demand | Inst | Nút | Cung | Demand |
|---|---|---|---|---|---|---|---|
| 01 | 20 | 80 | 40 | 11 | 200 | 1000 | 400 |
| 02 | 30 | 150 | 45 | 12 | 200 | 898 | 400 |
| 03 | 50 | 250 | 20 | 13 | 200 | 1000 | 2000 |
| 04 | 50 | 250 | 200 | 14 | 250 | 1108 | 600 |
| 05 | 100 | 396 | 100 | 15 | 250 | 1250 | 600 |
| 06 | 100 | 500 | 500 | 16 | 250 | 1452 | 4800 |
| 07 | 100 | 500 | 800 | 17 | 300 | 1270 | 2000 |
| 08 | 150 | 654 | 200 | 18 | 300 | 1500 | 2000 |
| 09 | 150 | 750 | 200 | 19 | 300 | 1998 | 6000 |
| 10 | 150 | 966 | 1000 | 20 | 400 | 2000 | 6000 |

Tất cả: $T=\{0,1\}$, $\text{maxSeg}=6$, mỗi instance có đúng một intervention tại $t=1$ gồm **đúng 1 cung** bị tắt.

Ngân sách $\beta(1)$ theo instance (đọc từ file `scenario`):

| Inst | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| $\beta(1)$ | 51 | 63 | 53 | 44 | 1 | 13 | 90 | 13 | 18 | 1 |

| Inst | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 |
|---|---|---|---|---|---|---|---|---|---|---|
| $\beta(1)$ | 89 | 13 | 12 | 13 | 54 | 13 | 1 | 89 | 13 | 90 |

Ngoài ra: 188 giá trị lưu lượng bằng 0 (ví dụ instance 20 có 98), nên có demand có lưu lượng 0 tại một thời điểm. Có thể bỏ qua các demand này khi tính tải tại thời điểm đó nhưng vẫn giữ trong ràng buộc ngân sách.

---

## 6. Định dạng đầu ra (tùy chọn nhưng nên làm)

Đề yêu cầu xuất nghiệm dạng `srpaths` để kiểm tra độc lập:
```json
{ "srpaths": [ {"d": 0, "t": 0, "w": [3]}, {"d": 0, "t": 1, "w": [3]} ] }
```
- `d`: ID demand (vị trí trong danh sách).
- `t`: thời điểm.
- `w`: danh sách waypoint, dùng ID nút trong JSON.
- Demand không có waypoint có thể bỏ qua.

Nên xuất file này cho mỗi instance và kiểm tra lại: tính lại tải từ waypoint, so với $U(a,t)$ của solver. Đây là cách phát hiện lỗi mô hình.

---

## 7. Các bước thực hiện (theo readme)

| # | Việc | Đầu ra |
|---|---|---|
| 1 | Đọc đề | Hiểu bài toán (đã xong trong file này) |
| 2 | Đọc JSON → đồ thị $G(0)$ (Pluto) | Graph, ánh xạ id |
| 3 | Tính $r(\cdot,\cdot,\cdot,0)$ theo **ECMP từng chặng** (mục 4) | Ma trận $r$ thưa |
| 4 | Module **Data**: $r$, $c$, $\delta(d,0)$, maxSeg | Tham số |
| 5 | Mô hình $t=0$: (1), (2), (3), (7), (8), mục tiêu min MLU | Mô hình JuMP |
| 6 | Kiểm tra toy (mục 4.4) | Xác nhận $r$ và tải |
| 7 | Chạy SetA, $t=0$, **1800 s** | Bảng 1 |
| 8 | Tính $r(\cdot,\cdot,\cdot,1)$ trên $G_1$; thêm (4) và biến $y$ | Mô hình $t=0,1$ |
| 9 | Chạy SetA, $t=0,1$, **3600 s** | Bảng 2 |

**Lưu ý:** readme bước 9 ghi "only time period 0" nhưng nội dung là $t=0$ và $t=1$ có ngân sách. Nên hiểu là $t=0$ và $t=1$, và ghi rõ trong báo cáo.

---

## 8. Thực nghiệm

### 8.1. Cấu hình
- Giới hạn: 1800 s (bước 7), 3600 s (bước 9).
- **CPU time** chỉ đo lời gọi `optimize!`, không tính đọc file hay dựng mô hình.
- **10 lần chạy** mỗi instance. Báo cáo trung bình.
- Ghi môi trường: phiên bản Julia, JuMP, solver và phiên bản, CPU, RAM, hệ điều hành, số luồng.

### 8.2. Bảng kết quả yêu cầu

| Cột | Ý nghĩa |
|---|---|
| Số đỉnh | $n$ |
| Số cung | $m$ |
| Số demand | $\lvert D\rvert$ |
| Objective (optimal hoặc best) | giá trị nghiệm tốt nhất tìm được |
| CPU time | thời gian `optimize!` trung bình |
| Status | Optimal / Not Optimal / Infeasible |
| Gap | nếu Not Optimal: $1 - \dfrac{\text{cận dưới tốt nhất}}{\text{nghiệm tốt nhất}}$ |
| Số nút B&B | node count của solver |

**Về gap:** công thức của readme là $1 - \mathrm{LB}/\mathrm{UB}$. Với bài toán cực tiểu, $\mathrm{LB} \le \mathrm{UB}$, nên gap $\in [0,1]$. Cận dưới lấy từ solver (`objective_bound`).

### 8.3. Lưu ý
- Instance không giải được trong giới hạn phải ghi Not Optimal kèm gap, không được bỏ qua.
- **Infeasible không nên xảy ra.** Nghiệm "không waypoint" ($x^{dt}_{sd,\tau_d}=1$, mọi $x$ khác $=0$) thỏa (1), (2) và (4) (có $\text{dist}=0$), còn (3) chỉ định nghĩa $U$ nên không giới hạn. Đã kiểm tra: mọi demand đều có đường từ $s$ đến $\tau$ ở cả $G_0$ và $G_1$ trên cả 20 instance. Nếu solver trả về Infeasible thì đó là **lỗi mô hình hoặc lỗi dữ liệu**, không phải kết quả hợp lệ.
- **Ngân sách rất khác nhau giữa các instance** (xem mục 5.3): $\beta(1)=1$ ở instance 05, 10, 17 nên gần như cố định cấu hình, còn $\beta(1)=90$ ở instance 07 và 20.

---

## 9. Quyết định cần chốt

1. **Solver:** HiGHS (mã mở), Gurobi/CPLEX (cần giấy phép học thuật), hay Cbc.
2. **Mục tiêu:** min MLU (đơn giản) hay lex nhiều bước (đúng đề nhưng tốn thời gian).
3. **Định nghĩa $r$:** chắc chắn là ECMP từng chặng. Cần ghi chú về sự khác biệt với `calculating_r.pdf` và hỏi giảng viên nếu cần.
4. **Cung bị tắt:** $r=0$ và $FG$ trên $G_t$. Nên xác nhận.
5. **Bước 9:** $t=0$ và $t=1$.
6. **Gap:** xác nhận công thức với giảng viên.
7. **Ngôn ngữ mô hình:** JuMP (theo gợi ý readme về `optimize!`).

---

## 10. Rủi ro và điểm dễ sai

- **Dùng công thức đếm đường** thay vì ECMP từng chặng. Đây là lỗi nghiêm trọng nhất, đã kiểm chứng ở mục 4.
- **Nhầm $t$ (đích) với $t$ (thời điểm).** Đặt tên khác nhau trong code.
- **Quên tính $r$ trên $G_1$.** Dùng $r$ của $G_0$ cho $t=1$ là sai.
- **Tin cờ `multigraph` và dùng notebook Pluto v2 nguyên bản.** Notebook sẽ báo lỗi với 10/20 instance (xem mục 5.1).
- **So sánh bằng nhau với metric thực** (instance 05, 08, 12, 14) mà không có dung sai.
- **Coi Infeasible là kết quả bình thường.** Mô hình luôn khả thi (xem mục 8.3).
- **Nhầm id cung với chỉ số cung** trong `interventions`.
- **Đồ thị có hướng:** $(u,v)$ và $(v,u)$ khác nhau.
- **Số biến quá lớn** với instance lớn. Dùng biến dạng sparse, không tạo tensor dense $r$.
- **Đo thời gian sai:** chỉ tính `optimize!`.
- **Tràn số:** dùng Float64 cho số đường (nếu cần đếm), tải là Float64.
- **Kiểm tra nghiệm:** xuất srpaths và tính lại tải để so với solver.

---

## 11. Checklist

- [ ] Hiểu rõ ECMP từng chặng, $r$, đoạn, waypoint, MLU, budget.
- [ ] Đọc JSON, ánh xạ id nút và id cung.
- [ ] Tính $r$ theo ECMP từng chặng cho $G_0$.
- [ ] Kiểm chứng toy: $r(0,5,(1,4))=0{,}5$, $\mathrm{load}(4,6)=0{,}3125$, MLU $0{,}4375$ và $0{,}3750$.
- [ ] Xây mô hình $t=0$, chạy setA-01 để kiểm tra.
- [ ] Chạy SetA $t=0$ với 1800 s, 10 lần, lập bảng.
- [ ] Tính $r$ trên $G_1$, thêm (4), chạy SetA $t=0,1$ với 3600 s, 10 lần, lập bảng.
- [ ] Kiểm tra nghiệm bằng srpaths.
- [ ] Viết báo cáo 10 trang: giới thiệu, mô hình (data, biến, mục tiêu, ràng buộc), thực nghiệm (instance, môi trường, bảng).

---

## 12. Kết quả kiểm chứng

### Đã kiểm tra bằng code trên dữ liệu thật
| Nội dung | Kết quả |
|---|---|
| Ví dụ toy: $r$, tải $a_{4,6}$, MLU (hai trường hợp) | Khớp đề khi dùng ECMP từng chặng; không khớp khi đếm đường |
| Số nút, cung, demand của 20 instance | Khớp bảng mục 5.3 |
| $T=2$, $\text{maxSeg}=6$, một intervention $t=1$ với một cung | Đúng cho cả 20 |
| Id nút liên tục $0..n-1$, id cung liên tục $0..m-1$ | Đúng |
| Không có cung song song, không khuyên | Đúng cho cả 20 |
| Không có demand $s=\tau$, không có cặp $(s,\tau)$ trùng | Đúng cho cả 20 |
| Mọi demand đạt được ở $G_0$ và $G_1$ | Đúng cho cả 20 |

### Đã phát hiện và sửa trong lần kiểm tra này
1. Cờ `multigraph: true` ở 10 instance làm notebook Pluto v2 báo lỗi (trước đó file ghi sai là đồ thị đơn).
2. Metric không nguyên ở 4 instance (trước đó file ghi sai là số nguyên).
3. "Infeasible có thể xảy ra" là sai: mô hình luôn khả thi.

### **Chưa** kiểm chứng (cần thận trọng khi cài đặt)
- **Chưa giải mô hình MILP nào.** Các ràng buộc (1)–(4) được chép từ đề, chưa chạy với solver. Nên giải toy bằng JuMP và so với đáp án của đề (MLU tối ưu có thể thấp hơn 0.3750 nếu có nghiệm tốt hơn; đề không nêu giá trị tối ưu).
- **Chưa kiểm tra $t=1$ của toy** bằng số: đề chỉ cho hình, không cho bảng tải.
- **Chưa xác nhận với giảng viên:** ý nghĩa bước 9, công thức gap, việc dùng min MLU thay cho lexicographic, và việc dùng ECMP từng chặng thay cho công thức trong `calculating_r.pdf`.
- **Chưa ước lượng độ thưa thực tế của $r$** và thời gian tính $r$ cho instance lớn (setA-20).
- **Chưa kiểm tra hành vi của `allpaths=true` trong Graphs.jl** với metric thực.

---

## 13. Tài liệu tham khảo

**Đề bài:**
1. C. Filsfils et al., *Segment Routing Architecture*, RFC 8402, 2018.
2. A. Hagberg, P. Swart, D. Schult, *Exploring network structure, dynamics, and function using NetworkX*, SciPy 2008.

**Từ `recommended_optimization_lecture`:**
3. Kochenderfer & Wheeler, *Algorithms for Optimization* (MIT): https://algorithmsbook.com/optimization/
4. Chvátal, *Linear Programming*.
5. Cook, Cunningham, Pulleyblank, *Combinatorial Optimization*.
6. Conforti, Cornuéjols, Zambelli, *Integer Programming*.
7. Boyd & Vandenberghe, *Convex Optimization*: https://web.stanford.edu/~boyd/cvxbook/bv_cvxbook.pdf
8. Birge & Louveaux, *Introduction to Stochastic Programming*.
9. Ben-Tal, El Ghaoui, Nemirovski, *Robust Optimization*: https://www2.isye.gatech.edu/~nemirovs/FullBookDec11.pdf
10. Wright, *Optimization for Data Analysis*.
11. Tuy & Horst, *Global Optimization*.
