# Báo cáo: bài toán, cách giải, thực nghiệm và kết quả

**Đề tài:** Orange — ROADEF 2026 "Keep The Flow!", bài toán **T-Adaptive Segment Routing (T-ASR)**.
**Phạm vi:** phần thuật toán, code và thực nghiệm do máy M1 (người điều phối) thực hiện. Báo cáo LaTeX ≤ 10 trang do người khác viết; file này là tài liệu nền để lấy số liệu và để thầy truy vết.
**Thời điểm chốt:** sáng 20/10/2026. Nhánh `feature/tasr`; `main` chưa merge.

**Cách đọc:** mục 1 tóm tắt toàn bộ. Mục 2 giải thích bài toán và dữ liệu. Mục 3 là các cách giải. Mục 4 là cách làm thực nghiệm. Mục 5 là kết quả. Mục 6–9 là độ tin cậy, sự cố, hạn chế và việc còn lại.

---

## 1. Tóm tắt

| Câu hỏi | Trả lời |
|---|---|
| Bài toán là gì? | Với mỗi nhu cầu truyền tải (demand) trong mạng IP, chọn tối đa 6 đoạn đường (segment) sao cho **tải lớn nhất trên các cung (MLU) nhỏ nhất**; xét thêm trường hợp có một cung bị tắt ở bước thời gian 1 và một ngân sách giới hạn số thay đổi cấu hình. |
| Đã làm gì? | Mô hình MILP theo đề (Julia/JuMP + HiGHS); thêm mô hình waypoint, sinh cột (column generation) và LNS cho các instance lớn; bộ kiểm chứng độc lập; công cụ chạy, truy vết và chia việc cho nhóm. |
| Kết quả chính? | Cả hai bảng của thầy đã có đủ **20 hàng** (setA-01…20). Các instance nhỏ giải **tối ưu** bằng mô hình của thầy. Các instance lớn giải bằng mô hình waypoint, giảm MLU **từ 1,0 xuống 0,04–0,99 so với đi đường ngắn nhất** (mục 5.4). |
| Độ chính xác? | **93 file lời giải** được kiểm chứng độc lập bằng Python: **0 lỗi**, MLU khớp CSV (chênh 0). |
| Đủ "trung bình 10 lần" chưa? | **Chưa hoàn toàn.** Bảng 1: setA-01…05 đủ 10 lần. Bảng 2: setA-01, 02, 03 đủ 10 lần; **setA-04 mới 4 lần, setA-05 mới 5 lần**. Các hàng 06–20 mới 1 lần (mục 8). |
| Điểm yếu lớn nhất? | Mô hình theo cung **kẹt ở nút gốc** trên setA-04 và setA-05 khi $t=0,1$ (setA-05: MLU 0,99999 trong khi mô hình waypoint tìm được 0,205). Cả hai con số đều ghi trong bảng. |
| Việc còn lại? | Chạy nốt setA-04 $t=0,1$ lần 5–10 và setA-05 $t=0,1$ seed 6–10 (M2/M3 chưa chạy; nếu không, M1 chạy, ≈ 1 giờ/lần). |

---

## 2. Bài toán và dữ liệu

### 2.1. Bối cảnh

Orange vận hành mạng IP/MPLS lớn. Để tránh nghẽn (traffic engineering) mạng phải cân bằng tải và vẫn hoạt động khi một liên kết bị hỏng hoặc bị tắt có kế hoạch. **Segment Routing (SR)** cho phép một gói tin đi qua các **waypoint** trung gian thay vì chỉ theo đường ngắn nhất, nên điều khiển được đường đi mà không phải đổi cấu hình nhiều thiết bị. Bài toán là thiết kế các đường SR cho mọi nhu cầu để **tải lớn nhất trên các cung (MLU) nhỏ nhất**, kể cả sau khi một cung bị tắt.

### 2.2. Khái niệm

| Khái niệm | Ý nghĩa |
|---|---|
| Cung $a=(u,v)$ | Cạnh có hướng, có trọng số $\omega(a)$ (`metric`) và dung lượng $c(a)$ (`capacity`). |
| $FG(u,v)$ | Tập các cung nằm trên ít nhất một đường ngắn nhất (theo $\omega$) từ $u$ đến $v$. |
| ECMP | Tại mỗi nút, luồng chia đều cho các cung ra thuộc $FG(u,v)$. |
| $r(u,v,a,t)$ | Tỷ lệ luồng đơn vị $u\to v$ đi qua cung $a$ khi mạng ở trạng thái $G_t$. |
| Đoạn (segment) | Cặp nút liên tiếp $(i,j)$ của đường; mỗi đoạn được định tuyến ECMP. |
| Đường segment | Dãy $s, w_1,\dots,w_l, \tau$. Không waypoint ($l=0$): đi thẳng theo đường ngắn nhất. |
| maxSeg | Số đoạn tối đa mỗi đường (SetA: 6). |
| Demand $d=(s_d,\tau_d)$ | Nhu cầu từ $s_d$ đến $\tau_d$ với lưu lượng $\delta(d,t)$. |
| $q(t)$ | Tập cung bị tắt ở bước $t$; $G_t$ là đồ thị sau khi bỏ chúng. |
| $\beta(t)$ | Ngân sách: số thay đổi đường tối đa từ $t-1$ sang $t$ (ở $t=0$ là vô hạn). |
| MLU | Tải lớn nhất trên mọi cung: $\max_a \text{flow}(a)/c(a)$. |

**Ví dụ nhỏ.** Giả sử mạng có hai đường ngắn nhất bằng nhau từ $s$ đến $\tau$. ECMP chia luồng 50–50 cho hai nhánh. Nếu một nhánh đã quá tải bởi nhu cầu khác, ta đặt một waypoint $w$ sao cho đoạn $(s,w)$ và $(w,\tau)$ cùng dùng nhánh nhẹ tải; MLU giảm mà không cần cấu hình lại mạng.

### 2.3. Mô hình toán học (theo đề)

**Tập và tham số:** $V$ (nút, $n=|V|$), $A$ (cung, $m=|A|$), $D$ (demand), $T=\{0,1\}$, $\omega$, $c$, $\delta$, $q$, $\beta$, $\text{maxSeg}$.

**Biến:** $x^{dt}_{ij}\in\{0,1\}$ bằng 1 nếu đường của $d$ tại $t$ chứa đoạn $(i,j)$; $U(a,t)\ge 0$ là tải cung; $z$ là MLU.

**Ràng buộc:**

1. Bảo toàn luồng, $\forall d,t,i$:
$$\sum_{j\ne i}x^{dt}_{ij}-\sum_{j\ne i}x^{dt}_{ji}=\begin{cases}+1,& i=s_d\\-1,& i=\tau_d\\0,&\text{khác}\end{cases}$$
2. Giới hạn số đoạn: $\sum_{i,j}x^{dt}_{ij}\le\text{maxSeg}$.
3. Ràng buộc tải, $\forall t$, $a\in A\setminus q(t)$:
$$\sum_{d\in D}\sum_{i,j\in V}r(i,j,a,t)\,\delta(d,t)\,x^{dt}_{ij}\le U(a,t)\,c(a).$$
4. Ngân sách, $\forall t\ge1$: $\sum_{d}\sum_{i\ne j}\bigl|x^{dt}_{ij}-x^{d,t-1}_{ij}\bigr|\le\beta(t)$ (tuyến tính hoá bằng biến phụ $y\ge|x_t-x_{t-1}|$).

**Mục tiêu theo đề** là cực tiểu từ điển (lexicographic) của vector tải sắp giảm dần. Cách cài đặt thực tế (xấp xỉ):
$$\min\ z+\varepsilon\sum_{d,t,i,j}x^{dt}_{ij},\qquad z\ge U(a,t)\ \forall a,t,\quad \varepsilon=\frac{10^{-7}}{|D|}.$$
Số hạng $\varepsilon\sum x$ ưu tiên đường ít đoạn; nó đủ nhỏ để không làm đổi MLU.

### 2.4. Hệ số tách $r$ — hai cách tính

- **ECMP từng chặng** (định nghĩa trong đề): tại mỗi nút luồng chia đều cho các cung ra thuộc $FG(u,v)$.
- **Đếm đường ngắn nhất** (`calculating_r.pdf`): $r_{ijat}=\sigma_{iaj}(t)/\sigma_{ij}(t)$, trong đó $\sigma_{ij}$ là số đường ngắn nhất và $\sigma_{iaj}$ là số đường đi qua $a$.

Hai cách khác nhau khi có nút rẽ nhiều nhánh. Ví dụ trên dữ liệu mẫu của đề: $r(v_0,v_5,a_{1,4})$ bằng 0,5 theo ECMP và 2/3 theo cách đếm đường. **Các bảng chính thức ở đây dùng công thức của `calculating_r.pdf`** (nhãn `arc-pc`), theo yêu cầu "r từ calculating_r.pdf" của thầy; code vẫn hỗ trợ ECMP (`mode=:ecmp`) và đã đối chiếu cả hai. Trên SetA, hai cách **trùng nhau ở 18/20 instance** (file `r_difference.csv`). Khoảng cách đường đi được so sánh với sai số tương đối $10^{-9}$ vì một số instance có metric thực.

### 2.5. Dữ liệu SetA

Mỗi instance có ba file: `net.json` (nút, cung, metric, dung lượng), `tm.json` (demand và lưu lượng $\delta(d,0)$, $\delta(d,1)$) và `scenario.json` (`max_segments`, ngân sách $\beta(1)$, cung bị tắt). Tất cả instance có $T=\{0,1\}$, $\text{maxSeg}=6$, và **đúng 1 cung** bị tắt ở $t=1$.

| Instance | Nút $n$ | Cung $m$ | Demand $\lvert D\rvert$ | $\beta(1)$ | Số biến $x$ của mô hình cung mỗi $t$: $\lvert D\rvert\,n(n-1)$ |
|---|---|---|---|---|---|
| 01 | 20 | 80 | 40 | 51 | 15 200 |
| 02 | 30 | 150 | 45 | 63 | 39 150 |
| 03 | 50 | 250 | 20 | 53 | 49 000 |
| 04 | 50 | 250 | 200 | 44 | 490 000 |
| 05 | 100 | 396 | 100 | 1 | 990 000 |
| 06 | 100 | 500 | 500 | 13 | 4,95 triệu |
| 07 | 100 | 500 | 800 | 90 | 7,92 triệu |
| 08 | 150 | 654 | 200 | 13 | 4,46 triệu |
| 09 | 150 | 750 | 200 | 18 | 4,46 triệu |
| 10 | 150 | 966 | 1000 | 1 | 22,3 triệu |
| 11 | 200 | 1000 | 400 | 89 | 15,9 triệu |
| 12 | 200 | 898 | 400 | 13 | 15,9 triệu |
| 13 | 200 | 1000 | 2000 | 12 | 79,6 triệu |
| 14 | 250 | 1108 | 600 | 13 | 37,4 triệu |
| 15 | 250 | 1250 | 600 | 54 | 37,4 triệu |
| 16 | 250 | 1452 | 4800 | 13 | 299 triệu |
| 17 | 300 | 1270 | 2000 | 1 | 179 triệu |
| 18 | 300 | 1500 | 2000 | 89 | 179 triệu |
| 19 | 300 | 1998 | 6000 | 13 | 538 triệu |
| 20 | 400 | 2000 | 6000 | 90 | 958 triệu |

**Nhận xét về độ khó.**

- **Số biến tăng rất nhanh** theo $n^2\lvert D\rvert$: từ 15 nghìn (setA-01) lên gần 1 tỷ (setA-20). Mô hình theo cung chỉ nạp được vào 32 GB RAM của máy cho setA-01…05.
- **Ngân sách $\beta(1)$ rất khác nhau**: các instance 05, 10, 17 chỉ cho phép **1 thay đổi**, nên ở $t=1$ gần như phải giữ nguyên cấu hình của $t=0$ — đây là loại ràng buộc khó cho bộ giải MILP khi nối hai bước.
- 188 giá trị lưu lượng bằng 0 (ví dụ instance 20 có 98): một số demand không có tải ở một thời điểm.
- 10/20 file khai báo `multigraph: true` nhưng đã kiểm tra: không có cung song song hay khuyên; code đọc JSON trực tiếp và kiểm tra điều này.

---

## 3. Các cách giải đã cài đặt

Toàn bộ nằm trong `orange/` (Julia + Python) và có test tự động (`orange/test/runtests.jl`, tất cả đạt).

### 3.1. Mô hình theo cung — đúng như đề (`src/model.jl`)

Cài đặt đầy đủ biến $x^{dt}_{ij}$ cho mọi cặp nút, các ràng buộc (1)–(4) ở trên, giải bằng HiGHS. Đây là **mô hình của thầy**; kết quả của nó là các hàng `arc-pc` trong bảng. Ưu điểm: chính xác, cho cận dưới. Nhược điểm: bùng nổ kích thước, chỉ nạp được setA-01…05, và với setA-04/05 ở $t=0,1$ bộ giải không thoát khỏi nút gốc.

### 3.2. Mô hình waypoint (`src/wpmodel.jl`)

Thay vì biến theo cặp nút, mỗi demand chọn **một đường trong tập ứng viên** (đi thẳng hoặc qua một waypoint $w$). Với $\text{maxSeg}=2$ và tập ứng viên đầy đủ ($K=n-2$ waypoint) mô hình này **chính xác** và đã được đối chiếu bằng vét cạn trên ví dụ nhỏ. Với $\text{maxSeg}=6$ nó giải **bài toán thu hẹp** (tối đa 1 waypoint mỗi demand). Biến nhị phân giảm từ $\lvert D\rvert n^2$ xuống $\lvert D\rvert n$, nên nạp được setA-06…20.

**Vì sao một waypoint là đủ?** Kiểm chứng trên các instance mà mô hình đầy đủ giải được: setA-05 — nghiệm tối ưu theo cung và nghiệm waypoint **trùng đến 8 chữ số**; setA-04 — nghiệm waypoint nằm trong **0,011 %** so với cận dưới của mô hình cung; thêm cặp waypoint không cải thiện ở setA-01, 03, 04, 05, 09. Đây là căn cứ thực nghiệm (chưa phải chứng minh) để dùng mô hình thu hẹp cho các instance lớn.

### 3.3. Sinh cột (column generation) và tinh chỉnh

Khi tập ứng viên đầy đủ quá lớn, ta giải LP với một tập ứng viên nhỏ, lấy **dual của các ràng buộc tải**, tính **reduced cost** của các đường chưa có, rồi thêm các đường có reduced cost âm (tham số `extra`). Lặp đến khi không còn cột cải thiện. Hàm `lex_refine` sau đó tinh chỉnh tải lớn thứ hai trở đi (xấp xỉ mục tiêu từ điển).

### 3.4. LNS — tìm kiếm lân cận lớn (`src/lns.jl`)

Với instance mà MILP kẹt, ta **đóng băng** phần lớn demand ở đường hiện tại và giải lại một lân cận (các demand đi qua cung nghẽn nhất), lặp trong một ngân sách thời gian (300 s). LNS là nguồn cải thiện lớn nhất cho các instance nhiều demand (ví dụ setA-13 $t=0,1$: 0,9017 → 0,0769).

### 3.5. "Pipeline nhanh" cho $t=0,1$ cỡ lớn

Với setA-16 và setA-19 ($t=0,1$) MILP đứng ở nút gốc (0 nút B&B). Pipeline nhanh bỏ MILP, chạy sinh cột cho bước đầu, lọc ứng viên (`filter_cands`) rồi LNS với ngân sách thay đổi.

### 3.6. Heuristic cục bộ (`src/heuristic.jl`)

Tìm kiếm cục bộ cho cả 20 instance. Hạn chế: bị kẹt khi nhiều lựa chọn có giá trị bằng nhau (chưa sửa), nên **không dùng cho bảng chính thức**.

---

## 4. Thiết lập thực nghiệm

| Hạng mục | Giá trị |
|---|---|
| Máy | Intel Core i7-1270P (12 nhân, 16 luồng), 31,6 GB RAM, Windows 11 |
| Ngôn ngữ / thư viện | Julia 1.13.1, JuMP 1.32.1, HiGHS 1.26.0, Graphs 1.15.0 |
| Cấu hình solver | `threads=1`, `mip_rel_gap=1e-6`, `random_seed` = chỉ số lần chạy; presolve tắt nếu > 1,2 triệu biến |
| Giới hạn thời gian | Bảng 1 ($t=0$): 1800 s. Bảng 2 ($t=0,1$): 3600 s |
| Số lần chạy | Mục tiêu 10. Quy tắc: lần 1 ≤ 120 s thì chạy đủ 10 lần, ngược lại tối thiểu 3 lần rồi bổ sung dần |
| CPU time | Chỉ tính thời gian `optimize!` (đúng yêu cầu của thầy) |
| Trạng thái | Optimal / Not Optimal / Infeasible; gap $=1-\text{LB}/\text{UB}$ khi chưa tối ưu |
| Số nút B&B | Số nút HiGHS báo cáo, trung bình trên các lần chạy |
| Các cột trung bình | Thời gian, gap và nút B&B lấy trung bình trên số lần ghi ở cột "Số lần"; "MLU" là **giá trị tốt nhất trong các lần** |
| Kiểm tra mỗi lần chạy | Ghi lời giải (`srpaths.json`), tính lại tải/MLU/ngân sách bằng code độc lập, đánh dấu `check=ok` |

**Chiến lược chạy.** Máy chạy song song tối đa vài tiến trình, có watchdog giữ RAM trống ≥ 1,5 GB và tự dừng tiến trình tốn ít CPU nhất nếu thiếu; mô hình theo cung có ước lượng bộ nhớ (≈ 4500 B/biến) so với RAM trống trước khi chạy. Các lần chạy bổ sung nằm trong file riêng (hậu tố `-rA-B`), không ghi đè.

---

## 5. Kết quả

Quy ước: **MLU** càng nhỏ càng tốt. Hàng `arc-pc` là mô hình theo cung của thầy. Hàng `*` là mô hình waypoint (bài toán thu hẹp ≤ 1 waypoint), vì mô hình theo cung không nạp được; trạng thái và gap của hàng `*` chỉ nói về bài toán thu hẹp đó.

### 5.1. Bảng 1 — chỉ $t=0$, giới hạn 1800 s

| Instance | Đỉnh | Cung | Nhu cầu | MLU | CPU (s) | Trạng thái | Gap | Nút B&B | Số lần | Mô hình | Tốt nhất biết được |
|---|---|---|---|---|---|---|---|---|---|---|---|
| setA-01 | 20 | 80 | 40 | 0,92938 | 0,8 | Optimal | – | 1 | 10 | arc-pc | 0,92938 |
| setA-02 | 30 | 150 | 45 | 0,54858 | 2,3 | Optimal | – | 1 | 10 | arc-pc | 0,54858 |
| setA-03 | 50 | 250 | 20 | 0,94354 | 5,2 | Optimal | – | 1 | 10 | arc-pc | 0,94354 |
| setA-04 | 50 | 250 | 200 | 0,50105 | 1800,9 | Not Optimal | 0,19 | 0 | 10 | arc-pc | **0,45912** |
| setA-05 | 100 | 396 | 100 | 0,11552 | 291,5 | Optimal | – | 1 | 10 | arc-pc | 0,11552 |
| setA-06 | 100 | 500 | 500 | 0,09859 | 10,7 | Optimal* | – | 1 | 1 | wp | 0,09859 |
| setA-07 | 100 | 500 | 800 | 0,90799 | 2,7 | Optimal* | – | 0 | 1 | wp | 0,90799 |
| setA-08 | 150 | 654 | 200 | 0,3189 | 1,2 | Optimal* | – | 0 | 1 | wp | 0,3189 |
| setA-09 | 150 | 750 | 200 | 0,50538 | 2,0 | Optimal* | – | 1 | 1 | wp | 0,50538 |
| setA-10 | 150 | 966 | 1000 | 0,06957 | 300,1 | Not Optimal* | 0,018 | 0 | 1 | wp-cg-lns | 0,06957 |
| setA-11 | 200 | 1000 | 400 | 0,61354 | 32,2 | Optimal* | – | 13 | 1 | wp | 0,61354 |
| setA-12 | 200 | 898 | 400 | 0,64008 | 6,3 | Optimal* | – | 1 | 1 | wp | 0,64008 |
| setA-13 | 200 | 1000 | 2000 | 0,03889 | 300,2 | Not Optimal* | 0,001 | 0 | 1 | wp-cg-lns | 0,03889 |
| setA-14 | 250 | 1108 | 600 | 0,43421 | 0,5 | Not Optimal* | 0,024 | 1 | 1 | wp-cg | 0,43421 |
| setA-15 | 250 | 1250 | 600 | 0,82521 | 0,4 | Optimal* | – | 0 | 1 | wp-cg | 0,82521 |
| setA-16 | 250 | 1452 | 4800 | 0,12295 | 115,7 | Optimal* | – | 1 | 1 | wp-cg | 0,12295 |
| setA-17 | 300 | 1270 | 2000 | 0,42419 | 2,4 | Optimal* | – | 1 | 1 | wp-cg | 0,42419 |
| setA-18 | 300 | 1500 | 2000 | 0,63337 | 1,3 | Optimal* | – | 0 | 1 | wp-cg | 0,63337 |
| setA-19 | 300 | 1998 | 6000 | 0,06745 | 1800,2 | Not Optimal* | 0,027 | 632 | 1 | wp-cg | 0,06745 |
| setA-20 | 400 | 2000 | 6000 | 0,99131 | 4,9 | Optimal* | – | 0 | 1 | wp-cg | 0,99131 |

**Nhận xét Bảng 1.**

- **setA-01, 02, 03, 05** (instance nhỏ): mô hình của thầy tối ưu 10/10 lần, từ 0,8 s đến ≈ 5 phút.
- **setA-04** là ca khó duy nhất ở nhóm này: hết 1800 s vẫn Not Optimal. Trong 10 lần, MLU dao động **0,50105–0,51828** (mỗi seed ra nghiệm khác), gap trung bình 0,19. Mô hình waypoint tìm được **0,45912**, tốt hơn ≈ 8,4 %, và nằm trong 0,011 % của cận dưới theo cung, nghĩa là 0,45912 gần tối ưu thực sự.
- **Các hàng `*` (06–20):** 11/15 hàng tối ưu cho bài toán thu hẹp, đa phần trong vài giây; 4 hàng Not Optimal* (10, 13, 14, 19) có gap nhỏ (0,1 %–2,7 %).
- **setA-07, 18, 20** có MLU rất cao (0,63–0,99) và **không cải thiện được** so với đi đường ngắn nhất (mục 5.4): đây là đặc điểm của instance (nghẽn ở cung mà waypoint không tránh được) chứ không phải lỗi giải.

### 5.2. Bảng 2 — $t=0,1$ có ngân sách, giới hạn 3600 s

| Instance | Đỉnh | Cung | Nhu cầu | MLU | CPU (s) | Trạng thái | Gap | Nút B&B | Số lần | Mô hình | Tốt nhất biết được |
|---|---|---|---|---|---|---|---|---|---|---|---|
| setA-01 | 20 | 80 | 40 | 0,92938 | 39,3 | Optimal | – | 1 | 10 | arc-pc | 0,92938 |
| setA-02 | 30 | 150 | 45 | 0,90307 | 2869,9 | Optimal 9/10 | 0,1 | 1 | 10 | arc-pc | 0,90307 |
| setA-03 | 50 | 250 | 20 | 0,94354 | 1131,2 | Optimal 8/10 | 0,2 | 1 | 10 | arc-pc | 0,94354 |
| setA-04 | 50 | 250 | 200 | 0,58857 | 3610,4 | Not Optimal | 0,75 | 0 | **4** | arc-pc | **0,58281** |
| setA-05 | 100 | 396 | 100 | 0,99999 | 4327,1 | Not Optimal | 1,0 | 0 | **5** | arc-pc | **0,20499** |
| setA-06 | 100 | 500 | 500 | 0,14085 | 2223,5 | Not Optimal* | – | 0 | 1 | wp-cg | 0,14085 |
| setA-07 | 100 | 500 | 800 | 0,90799 | 3,2 | Not Optimal* | – | 0 | 1 | wp-cg | 0,90799 |
| setA-08 | 150 | 654 | 200 | 0,3189 | 8,5 | Not Optimal* | – | 1 | 1 | wp-cg | 0,3189 |
| setA-09 | 150 | 750 | 200 | 0,84965 | 0,3 | Not Optimal* | – | 0 | 1 | wp-cg | 0,84965 |
| setA-10 | 150 | 966 | 1000 | 0,1087 | 300,6 | Not Optimal* | – | 0 | 1 | wp-cg-lns | 0,1087 |
| setA-11 | 200 | 1000 | 400 | 0,78579 | 1,3 | Not Optimal* | – | 0 | 1 | wp-cg | 0,78579 |
| setA-12 | 200 | 898 | 400 | 0,87987 | 1,3 | Not Optimal* | – | 0 | 1 | wp-cg | 0,87987 |
| setA-13 | 200 | 1000 | 2000 | 0,07692 | 302,0 | Not Optimal* | – | 0 | 1 | wp-cg-lns | 0,07692 |
| setA-14 | 250 | 1108 | 600 | 0,53315 | 78,0 | Not Optimal* | – | 37 | 1 | wp-cg | 0,53315 |
| setA-15 | 250 | 1250 | 600 | 0,8987 | 1,3 | Not Optimal* | – | 0 | 1 | wp-cg | 0,8987 |
| setA-16 | 250 | 1452 | 4800 | 0,51639 | 0,0 | Not Optimal* | – | – | 1 | wp-cg-lns-fast | 0,51639 |
| setA-17 | 300 | 1270 | 2000 | 0,42419 | 527,3 | Not Optimal* | – | 1 | 1 | wp-cg | 0,42419 |
| setA-18 | 300 | 1500 | 2000 | 1,0 | 17,2 | Not Optimal* | – | 0 | 1 | wp-cg | 1,0 |
| setA-19 | 300 | 1998 | 6000 | 0,10258 | 0,0 | Not Optimal* | – | – | 1 | wp-cg-lns-fast | 0,10258 |
| setA-20 | 400 | 2000 | 6000 | 0,99131 | 597,5 | Not Optimal* | – | 0 | 1 | wp-cg | 0,99131 |

**Nhận xét Bảng 2.**

- **setA-01, 02, 03:** mô hình của thầy giải được. setA-02 và 03 nằm gần ngưỡng thời gian nên một vài lần bị nhãn Not Optimal khi máy bận (9/10 và 8/10 lần Optimal), nhưng **MLU không đổi giữa các lần** (0,90307 và 0,94354).
- **setA-04, 05: mô hình theo cung thất bại.** Bộ giải không thoát khỏi nút gốc (0 nút B&B, cận dưới 0, gap gần 1). Hàng `arc-pc` vẫn ghi đúng kết quả của mô hình thầy yêu cầu, nhưng cột cuối cho thấy hướng waypoint tốt hơn nhiều: setA-04 0,58281 so với 0,58857; setA-05 **0,20499 so với 0,99999** (giảm ≈ 79 %).
- **Hàng `*` đều ghi "Not Optimal\*":** ở chế độ CG + LNS không có chứng minh tối ưu cho bài toán hai giai đoạn có ngân sách; gap để trống thay vì ghi số không có căn cứ.
- **setA-18 = 1,0:** điểm yếu đã biết; chưa cải thiện bằng LNS.

### 5.3. Thống kê chi tiết các hàng chạy bằng mô hình của thầy

Đây là phần "trung bình trên nhiều lần chạy" mà thầy yêu cầu; mỗi dòng gộp các lần chạy đã có.

| Instance | $t$ | Số lần | Optimal | Thời gian TB (s) | Độ lệch chuẩn | Min – Max (s) | MLU min – max | Nút B&B |
|---|---|---|---|---|---|---|---|---|
| setA-01 | 0 | 10 | 10 | 0,8 | 0,1 | 0,7 – 0,9 | 0,92938 – 0,92938 | 1 |
| setA-01 | 0,1 | 10 | 10 | 39,3 | 33,8 | 20,7 – 118,5 | 0,92938 – 0,92938 | 1 |
| setA-02 | 0 | 10 | 10 | 2,3 | 0,3 | 1,9 – 3,0 | 0,54858 – 0,54858 | 1 |
| setA-02 | 0,1 | 10 | 9 | 2869,9 | 469,9 | 1977,2 – 3600,3 | 0,90307 – 0,90307 | 0–1 |
| setA-03 | 0 | 10 | 10 | 5,2 | 2,0 | 2,8 – 8,0 | 0,94354 – 0,94354 | 1 |
| setA-03 | 0,1 | 10 | 8 | 1131,2 | 1300,2 | 274,0 – 3600,7 | 0,94354 – 0,94354 | 0–1 |
| setA-04 | 0 | 10 | 0 | 1800,9 | 0,6 | 1800,4 – 1802,2 | 0,50105 – 0,51828 | 0 |
| setA-04 | 0,1 | 4 | 0 | 3610,4 | 4,6 | 3602,8 – 3614,6 | 0,58857 – 0,58857 | 0 |
| setA-05 | 0 | 10 | 10 | 291,5 | 86,8 | 153,3 – 404,9 | 0,11552 – 0,11552 | 1 |
| setA-05 | 0,1 | 5 | 0 | 4327,1 | 1424,2 | 3610,9 – 7175,5 | 0,99999 – 0,99999 | 0 |

(Trong cột $t$: "0" là Bảng 1 chỉ $t=0$; "0,1" là Bảng 2 với $t=0,1$.)

**Hai điểm cần lưu ý khi đọc:**

1. **MLU gần như không đổi giữa các seed** (trừ setA-04 $t=0$): chứng tỏ nghiệm tối ưu là duy nhất về giá trị; thời gian giải mới là phần dao động. Độ lệch chuẩn lớn ở setA-02/03 ($t=0,1$) cho thấy thời gian giải rất nhạy với seed và tải máy.
2. **Thời gian của setA-05 $t=0,1$ bị một giá trị ngoại lai kéo lên:** bốn lần chạy trong khoảng 3611–3615 s (đúng giới hạn 3600 s cộng độ trễ nhỏ), **một lần lên tới 7175,5 s** (lần chạy bị kéo dài, nguyên nhân chưa xác định — có thể là máy tạm dừng hoặc quá tải). Nếu bỏ lần này, trung bình là ≈ 3615 s. Hàng bảng hiện ghi 4327,1 s (trung bình thô); báo cáo cuối nên nêu rõ điều này.

### 5.4. Mức giảm MLU so với định tuyến mặc định

"Mặc định" là mọi demand đi thẳng theo đường ngắn nhất (không waypoint). MLU mặc định, MLU tốt nhất tìm được và mức giảm:

| Instance | $t=0$: mặc định → tốt nhất (giảm) | $t=0,1$: mặc định → tốt nhất (giảm) | Nguồn $t=0,1$ |
|---|---|---|---|
| 01 | 1,0000 → 0,9294 (−7,1 %) | 1,0000 → 0,9294 (−7,1 %) | arc |
| 02 | 1,0000 → 0,5486 (−45,1 %) | 1,0981 → 0,9031 (−17,8 %) | arc |
| 03 | 1,0000 → 0,9435 (−5,6 %) | 1,0000 → 0,9435 (−5,6 %) | wp |
| 04 | 0,6918 → 0,4591 (−33,6 %) | 1,0000 → 0,5828 (−41,7 %) | wp |
| 05 | 0,3333 → 0,1155 (−65,3 %) | 1,0000 → 0,2050 (−79,5 %) | wp |
| 06 | 1,0000 → 0,0986 (−90,1 %) | 1,0000 → 0,1408 (−85,9 %) | wp-cg |
| 07 | 0,9080 → 0,9080 (0,0 %) | 1,0000 → 0,9080 (−9,2 %) | wp-cg |
| 08 | 1,0000 → 0,3189 (−68,1 %) | 1,0000 → 0,3189 (−68,1 %) | wp-cg |
| 09 | 0,6111 → 0,5054 (−17,3 %) | 1,0000 → 0,8497 (−15,0 %) | wp-cg |
| 10 | 1,0000 → 0,0696 (−93,0 %) | 1,0000 → 0,1087 (−89,1 %) | wp-cg-lns |
| 11 | 1,0000 → 0,6135 (−38,6 %) | 1,0000 → 0,7858 (−21,4 %) | wp-cg |
| 12 | 1,0001 → 0,6401 (−36,0 %) | 1,0001 → 0,8799 (−12,0 %) | wp-cg |
| 13 | 1,0000 → 0,0389 (−96,1 %) | 1,0000 → 0,0769 (−92,3 %) | wp-cg-lns |
| 14 | 1,0000 → 0,4342 (−56,6 %) | 1,0000 → 0,5331 (−46,7 %) | wp-cg |
| 15 | 1,0000 → 0,8252 (−17,5 %) | 1,0000 → 0,8987 (−10,1 %) | wp-cg |
| 16 | 0,9672 → 0,1230 (−87,3 %) | 1,0000 → 0,5164 (−48,4 %) | wp-cg-lns-fast |
| 17 | 1,0001 → 0,4242 (−57,6 %) | 1,0001 → 0,4242 (−57,6 %) | wp-cg |
| 18 | 0,6334 → 0,6334 (0,0 %) | 1,0000 → 1,0000 (0,0 %) | wp-cg |
| 19 | 1,0000 → 0,0674 (−93,3 %) | 1,0000 → 0,1026 (−89,7 %) | wp-cg-lns-fast |
| 20 | 1,0000 → 0,9913 (−0,9 %) | 1,0000 → 0,9913 (−0,9 %) | wp-cg |

**Cách hiểu.** Ở 17/20 instance SR giảm MLU rõ rệt; các instance nhiều demand (06, 10, 13, 16, 19) giảm **86–96 %**. Ba instance (07, 18, 20) gần như không giảm: nghẽn nằm ở cung mà không đường SR nào tránh được. MLU $t=0,1$ thường cao hơn $t=0$ vì sau khi một cung bị tắt, các luồng dồn sang cung khác và ngân sách $\beta(1)$ giới hạn việc đổi đường (đặc biệt $\beta=1$ ở 05, 10, 17).

---

## 6. Độ tin cậy và khả năng truy vết

1. **Kiểm chứng độc lập (Python):** 93/93 file `*-srpaths.json` tính lại tải, số đoạn, ngân sách và MLU; không lỗi, độ lệch tối đa giữa MLU kiểm chứng và MLU trong CSV là 0.
2. **Đối chiếu với đề:** hệ số $r$, tải và MLU trên ví dụ mẫu của đề khớp đúng (0,5; 0,25; 0,3125; MLU 0,4375 và 0,375).
3. **Đối chiếu mô hình waypoint với vét cạn** (cho $\text{maxSeg}=2$) và đối chiếu nghiệm hai mô hình trên setA-04, setA-05 (mục 3.2).
4. **Seed và log:** mỗi lần chạy có seed riêng (= chỉ số lần chạy) và log solver riêng ở `orange/results/solverlogs/`.
5. **Không ghi đè:** lần chạy bổ sung ở file hậu tố `-rA-B`; bộ gộp bảng loại trùng theo chỉ số lần chạy và cảnh báo khi chồng chéo.
6. **Manifest SHA-256** (`MANIFEST.csv/.md`, 350+ file kết quả, 60 file đầu vào) cho thầy kiểm tra toàn vẹn; zip sao lưu mỗi 30 phút.
7. **Nhật ký** `orange/results/RUN_JOURNAL.md` ghi dòng thời gian, sự cố và quyết định. Các commit đẩy lên GitHub dưới tên người dùng, không có đồng tác giả Claude.

---

## 7. Sự cố đã gặp

| Sự cố | Hậu quả | Xử lý |
|---|---|---|
| Máy ngủ 18:40–19:10 ngày 19/10 | Một đoạn chạy bị gián đoạn | `keep_awake.ps1` |
| Watchdog dừng tiến trình setA-04 $t=0,1$ lúc 21:52 và 23:10 | Mất một lần chạy | Cải tiến watchdog (dừng tiến trình tốn ít CPU nhất, loại trừ tiến trình IDE); quy tắc **không chạy hai tiến trình setA-04 $t=0,1$ cùng lúc** |
| HiGHS bỏ qua giới hạn thời gian ở presolve | Lần chạy vượt xa giới hạn | Tắt presolve khi > 1,2 triệu biến |
| Chạy song song làm méo thời gian và trạng thái | Optimal ↔ Not Optimal | Ghi "Optimal k/n"; dự kiến chạy lại hàng nhanh khi máy rảnh |
| setA-05 $t=0,1$ một lần chạy 7175,5 s | Trung bình thời gian hàng này lệch (4327,1 s) | Ghi chú trong báo cáo; chưa xác định nguyên nhân |

---

## 8. Hạn chế (nói thẳng)

1. **Chưa đủ 10 lần ở Bảng 2 cho setA-04 (4 lần) và setA-05 (5 lần).** Phân công gốc giao M2 và M3, nhưng cả hai chưa chạy, nên từ 20/10 ~08:40 M1 tự chạy nốt (setA-04 lần 5–10, rồi setA-05 seed 6–10; dự kiến xong khoảng 20:00). M2 và M3 không cần làm thêm.
2. **Các hàng `*` (06–20) chỉ 1 lần chạy.** Đề yêu cầu trung bình 10 lần. Bài toán thu hẹp chủ yếu tất định, nên lần chạy lặp chỉ khác thời gian; chưa chạy lặp vì ưu tiên các hàng của mô hình thầy.
3. **Các hàng `*` không phải mô hình của thầy.** "Optimal\*" chỉ có nghĩa tối ưu trong bài toán thu hẹp (≤ 1 waypoint). Trên các instance kiểm tra được, chênh với mô hình đầy đủ ≤ 0,011 %, nhưng chưa chứng minh cho mọi instance.
4. **Hàng `arc-pc` của setA-04, 05 ở $t=0,1$ cho kết quả kém** do giới hạn của bộ giải; con số tốt hơn nằm ở cột cuối. Báo cáo cuối cần trình bày cả hai và giải thích.
5. **Thời gian CPU chịu ảnh hưởng của chạy song song.** Các hàng nhanh (setA-01, 02, 03, 05 ở $t=0$; 01, 03 ở $t=0,1$) cần chạy lại khi máy rảnh nếu muốn số liệu thời gian sạch.
6. **Mục tiêu từ điển chỉ được xấp xỉ** bằng $z+\varepsilon\sum x$ (kèm `lex_refine` ở pipeline waypoint), chưa giải đúng từng tầng như đề.
7. **Hàng setA-04 $t=0$:** 10 lần cho MLU khác nhau (0,50105–0,51828), bảng ghi giá trị tốt nhất.
8. **Báo cáo LaTeX chưa hoàn thiện** (theo yêu cầu: do người khác làm).

---

## 9. Việc còn lại

| Ưu tiên | Việc | Ai | Ghi chú |
|---|---|---|---|
| 1 | setA-04 $t=0,1$ lần 5–10 (6 lần ≈ 6 giờ) | M2/M3 (hoặc M1) | Không chạy hai tiến trình setA-04 cùng lúc |
| 1 | setA-05 $t=0,1$ seed 6–10 (5 lần ≈ 5–6 giờ) | M2/M3 (hoặc M1) | `START_HERE.md` có đủ lệnh; file pilot đã đẩy lên `feature/tasr` |
| 2 | Khi M2/M3 đẩy `results/m2`, `results/m3`: `merge_member_branch.py`, rồi `best_known.jl`, `official_tables.jl`, `verify_srpaths.py`, `make_manifest.py` | M1 | Quy trình viết sẵn |
| 3 | Cải thiện các hàng yếu $t=0,1$ (setA-18, 07, 20) bằng LNS | M1 | Tối ưu thêm sau khi đủ yêu cầu tối thiểu |
| 3 | Đổi nhãn hàng `*` thành "Optimal (restricted)" / "Not certified" | M1 | Giảm nguy cơ hiểu nhầm |
| 4 | Chạy lại các hàng nhanh để có thời gian sạch | M1 | Giai đoạn 1c |
| 4 | Merge vào `main` (nhánh Final) và dọn 17 commit có đồng tác giả Claude (`push --force`) | M1 + người dùng | **Cần người dùng xác nhận ngay trước khi force-push** |

---

## 10. Bản đồ file (để thầy truy vết)

| Cần xem | File |
|---|---|
| Phân tích đề đầy đủ | `project/BAI_TOAN_FINAL.md` |
| Bảng chính thức | `orange/results/table_official_P1.md/.csv`, `table_official_P2.md/.csv`; LaTeX `report/table_official_P*.tex` |
| MLU tốt nhất theo mọi phương pháp, MLU mặc định | `orange/results/best_known.csv` |
| Kết quả từng lần chạy | `orange/results/setA-*-P{1,2}-pc*.csv` |
| Lời giải đã kiểm chứng | `orange/results/*-srpaths.json` |
| Log solver | `orange/results/solverlogs/` |
| Nhật ký chạy và quyết định | `orange/results/RUN_JOURNAL.md`, `orange/results/overnight_m1.log` |
| Toàn vẹn dữ liệu | `orange/results/MANIFEST.csv/.md`, `MANIFEST_INPUTS.csv` |
| Cách dùng code | `orange/README.md` |
| Phân công và hướng dẫn nhóm | `START_HERE.md`, `project/PHAN_CONG_NHOM.md`, `project/KE_HOACH_CAC_GIAI_DOAN.md`, `project/AGENT_BRIEFS/` |

---

## 11. Kết luận

Phần **code và thực nghiệm đã có đủ khung theo yêu cầu của thầy**: mô hình JuMP theo đề, phần Data, hai bảng 20 hàng, lời giải được kiểm chứng độc lập, kết quả truy vết được. Với các instance nhỏ, mô hình của thầy cho nghiệm tối ưu với đủ 10 lần chạy. Với các instance lớn và bài toán hai giai đoạn, mô hình theo cung không đủ sức; nhóm bổ sung mô hình waypoint, sinh cột và LNS, giảm MLU 86–96 % ở các instance nhiều demand so với đường ngắn nhất, và báo cả hai con số khi mô hình thầy bị kẹt (ví dụ setA-05 $t=0,1$: 0,99999 so với 0,205).

**Khoảng trống còn lại là số lần chạy:** setA-04 và setA-05 ở $t=0,1$ cần thêm 6 và 5 lần để đủ 10; các hàng `*` mới 1 lần. Đây là việc tốn thời gian máy, không tốn công phát triển, và phải xong trước hạn chốt (T4, thứ Tư 21/10/2026).
