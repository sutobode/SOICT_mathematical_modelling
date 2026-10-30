# Hướng dẫn đọc đề Challenge EURO/ROADEF 2026 – Orange "Keep The Flow!" (tiếng Việt)

> Đây là **bản tóm tắt và giải thích bằng lời của nhóm**, đi theo cấu trúc mục của tài liệu gốc
> `Challenge_Orange_ROADEF_2026_Subject.pdf` (12 trang). Đây không phải bản dịch nguyên văn. Các hình
> được dẫn chiếu theo số hình và số trang trong bản gốc; hãy mở bản gốc song song khi đọc.
> Phần **"Liên hệ với code"** là ghi chú riêng của nhóm, không có trong đề.

---

## 1. Giới thiệu (bản gốc trang 1)

- **Bối cảnh:** Orange vận hành các mạng xương sống IP/MPLS rất lớn, với hàng nghìn router và link và hàng chục nghìn demand lưu lượng. Bài toán thuộc lĩnh vực **Traffic Engineering (TE)**: điều chỉnh tham số mạng để dùng hạ tầng hiệu quả, tránh nghẽn và giữ chất lượng dịch vụ.
- **Yêu cầu vận hành:** mạng phải chịu được sự cố hỏng một link hoặc một nút. "Sự cố" hiểu theo nghĩa rộng, bao gồm cả việc nhà vận hành **chủ động tắt link để bảo trì**. Ngày càng cần chịu được nhiều sự cố cùng lúc (thiên tai, phá hoại).
- **Mục tiêu của challenge:** cho trước mạng và ma trận lưu lượng dự báo, tìm một **phương án định tuyến** giữ tải mạng ở mức chấp nhận được, kể cả khi có thiết bị không hoạt động.
- **Công nghệ:** **Segment Routing (SR)** (chuẩn IETF, RFC 8402). Định tuyến truyền thống chỉ đi theo đường ngắn nhất theo trọng số cạnh; tìm bộ trọng số vừa ít nghẽn vừa chịu lỗi là rất khó. SR cho phép gán cho mỗi gói tin một **segment path**, tức một dãy router trung gian (**waypoint**) mà gói phải đi qua lần lượt. Giữa hai waypoint liên tiếp, gói vẫn đi theo đường ngắn nhất. Nhờ vậy có thể đi lệch khỏi đường ngắn nhất từ nguồn đến đích mà không phải sửa nhiều cấu hình mạng.

---

## 2. Các khái niệm chuẩn bị (bản gốc trang 1–3)

**Mạng.** Bộ (G = (V, A), ω, c): G là đồ thị có hướng n đỉnh; ω(a) là **trọng số** (metric) của cạnh, dùng để tính đường ngắn nhất; c(a) là **dung lượng** (bandwidth) của cạnh. "Cạnh" (arc) và "link" được dùng như nhau.

**Forwarding graph và ECMP.** FG(u, v) là đồ thị con gồm **mọi cạnh nằm trên một đường ngắn nhất nào đó** từ u đến v. Nếu FG(u, v) không phải một đường đơn, cơ chế **ECMP (Equal-Cost Multi-Path)** hoạt động: tại mỗi đỉnh, luồng đi vào được **chia đều** cho các cạnh ra của đỉnh đó trong FG(u, v). Xem **Hình 1, trang 4**: trái là đi thẳng v0→v6 trên mạng trọng số đơn vị, phân số trên cạnh là tỉ lệ chia; phải là thêm waypoint v2.

**Segment path.** Một chuỗi forwarding graph nối tiếp nhau, ký hiệu ⟨s, w1, …, wℓ, t⟩. Nguồn s và đích t **không** tính là waypoint. ℓ = 0 nghĩa là đi theo đường ngắn nhất từ s đến t.

**Segment.** Một cặp nút liên tiếp trong segment path: (s, w1), (w1, w2), …, (wℓ, t). Mỗi segment (u, v) ứng với FG(u, v). Trong thực tế, số segment tối đa thường từ 4 đến 10, tùy giao thức và thiết bị.

**Demand.** Cặp (s, t) kèm **lưu lượng**. Lưu lượng thay đổi theo thời gian, nên là hàm σ: D × T → ℚ, gọi là **ma trận lưu lượng (traffic matrix)**.

**Routing scheme.** Một tập gồm k segment path, mỗi demand một đường.

**Chân trời thời gian.** T = {0, 1, …, h−1}. Phương án được quyết định trước cho cả giai đoạn (vài ngày đến vài tuần). Ví dụ: 7 thời kỳ cho lịch theo ngày trong một tuần, hoặc 4 thời kỳ cho lịch theo tuần trong một tháng. **t = 0 là trạng thái danh nghĩa** (không có sự cố). Ký hiệu T* = T \ {0}.

**Intervention.** Một thao tác bảo trì làm một link hoặc một nút ngừng hoạt động trong một thời gian. Về chức năng giống sự cố nhưng **biết trước**. Đề chỉ xét link bị tắt, vì tắt nút tương đương với tắt mọi link nối vào nút đó.

**Intervention scenario.** Hàm q: T* → 2^A cho biết tập cạnh bị tắt ở mỗi thời kỳ. **G_t** là đồ thị chỉ còn các cạnh A \ q(t).

**Budget (ngân sách thay đổi).** Mỗi lần đổi cấu hình định tuyến (thêm hoặc bớt waypoint) tốn công sức con người, nên cần giới hạn. Khoảng cách giữa hai phương án:

  dist(P, P′) = Σ_{d∈D} Σ_{i,j∈V, i≠j} | δ(p_d, ij) − δ(p′_d, ij) |

với δ(p_d, ij) = 1 nếu segment path của demand d chứa segment (i, j). Mỗi thời kỳ t ∈ T* có ngân sách β(t) là **số thay đổi tối đa so với thời kỳ trước**.

Một vài giá trị của dist, tính theo định nghĩa (trích theo ý từ Bảng 1, trang 3):
- ⟨s,w,t⟩ so với ⟨s,t⟩: 3, vì bỏ (s,w), (w,t) và thêm (s,t).
- ⟨s,w1,t⟩ so với ⟨s,w2,t⟩: 4.
- ⟨s,w1,w2,t⟩ so với ⟨s,w2,w1,t⟩: 6.

**Load (tải) và hệ số chia.** Tải của cạnh a ở thời kỳ t là **lượng luồng qua cạnh chia cho dung lượng**; có thể lớn hơn 1 khi nghẽn. **Hệ số chia r(u, v, a, t)** là tỉ lệ luồng từ u đến v đi qua cạnh a trong G_t (bằng 0 nếu a không thuộc FG(u, v)). Khi đó:

  λ(a, t) = [ Σ_{d∈D} Σ_{i,j∈V} r(i, j, a, t) · σ(d, t) · δ(p_d, ij) ] / c(a)

**MLU (Maximum Link Utilization).** Tải của cạnh tải cao nhất.

---

## 3. Bài toán T-Adaptive Segment Routing (T-ASR) (bản gốc trang 3–5)

### 3.1 Biến quyết định
x^{dt}_{ij} ∈ {0, 1} bằng 1 nếu segment path của demand d ở thời kỳ t chứa segment (i, j). Một nghiệm là một phương án định tuyến cho **mỗi** thời kỳ.

### 3.2 Ràng buộc

**(1) Bảo toàn luồng:** với mọi d = (s, t) ∈ D, t ∈ T và mọi i ∈ V,

  Σ_{j≠i} x^{dt}_{ij} − Σ_{j≠i} x^{dt}_{ji} = 1 nếu i = s; −1 nếu i = t; 0 nếu khác.

**(2) Số segment:** với mọi d, t: Σ_{i,j} x^{dt}_{ij} ≤ maxSeg. Số này tính cả segment đầu (từ nguồn đến waypoint đầu) và segment cuối (từ waypoint cuối đến đích).

**(3) Tải:** với mọi t ∈ T và mọi a ∈ A \ q(t):

  Σ_{d∈D} Σ_{i,j∈V} r(i, j, a, t) · σ(d, t) · x^{dt}_{ij} ≤ λ(a, t) · c(a)

**(4) Ngân sách:** với mọi t ∈ T*:

  Σ_{d∈D} Σ_{i,j∈V, i≠j} | x^{dt}_{ij} − x^{d,t−1}_{ij} | ≤ β(t)

Ràng buộc này giới hạn số thay đổi waypoint giữa hai thời kỳ liên tiếp. Đây chính là "độ phức tạp thứ hai" mà thầy nhắc tới ở cuối trang 4 của bản gốc.

### 3.3 Hàm mục tiêu
Mục tiêu thông dụng nhất trong TE là **cực tiểu tải của cạnh tải cao nhất**. Đề mở rộng thành **cực tiểu theo thứ tự từ điển (lexicographic)** toàn bộ tải của mọi cạnh ở mọi thời kỳ: trước hết giảm cạnh tải cao nhất, sau đó đến cạnh cao thứ hai, cứ thế tiếp tục.

Với L = {λ(a, t) | a ∈ A, t ∈ T}:

  (5) lex min { λ_(i) : 1 ≤ i ≤ |L| }, trong đó λ_(i) là phần tử lớn thứ i của L

Ràng buộc đi kèm: (6) gồm (1)–(4); (7) x nhị phân; (8) λ nhận giá trị hữu tỉ không âm.

### 3.4 Định nghĩa bài toán
- **Đầu vào:** mạng (G, ω, c); tập demand D; lưu lượng σ; T = {0, …, h−1}; scenario q; ngân sách β; maxSeg ≥ 2.
- **Đầu ra:** một phương án P^t cho mỗi t ∈ T thỏa (1)–(4) và tối ưu (5).

---

## 4. Ví dụ instance "toy" (bản gốc trang 5–7)

- **Mạng:** 7 đỉnh v0…v6. Mỗi cạnh có nhãn "trọng số; dung lượng" (xem **Hình 2, trang 5**).
- **Demand:** d0 = (v0, v5) và d1 = (v2, v5).
- **Hệ số chia tại t = 0 (Bảng 2, trang 6), một số giá trị:**
  - d0 có 3 đường ngắn nhất (a0,1 a1,3 a3,5 / a0,1 a1,4 a4,6 a6,5 / a0,1 a1,4 a4,3 a3,5). Theo ECMP: r(a0,1) = 1, r(a1,3) = r(a1,4) = 0.5, r(a3,5) = 0.75, r(a4,3) = r(a4,6) = r(a6,5) = 0.25.
  - d1 có 2 đường ngắn nhất: r(a2,4) = 1, các cạnh còn lại trên đường bằng 0.5.
- **Lưu lượng (Bảng 3):** σ(d0, 0) = 50, σ(d0, 1) = 100, σ(d1, 0) = 100, σ(d1, 1) = 50.
- **Ví dụ tính tải:** λ(a4,6, 0) = (0.25·50 + 0.5·100)/200 = 0.3125.
- **Intervention:** ở t = 1, tắt a1,3 và a1,4. Luồng của d0 ở t = 0 và t = 1 được minh họa ở **Hình 3, trang 7**.
- **So sánh hai nghiệm (Hình 4, trang 7):**
  - Không dùng waypoint: MLU = 0.4375.
  - Thêm waypoint v4 cho d0 ở t = 0: MLU giảm xuống 0.3750, đổi lại một số cạnh khác tải tăng lên.

> **Liên hệ với code:** thầy cung cấp cách tính r trong `calculating_r.pdf`. Cách này lấy r là **tỉ lệ số đường ngắn nhất i→j đi qua cạnh a** (đếm bằng Dijkstra), và code cài nó ở chế độ `pathcount`. Với d0, cách này cho r(a3,5) = 2/3 thay vì 0.75 như ECMP. Code có cả hai chế độ (`:pathcount`, `:ecmp`); kết quả chính thức dùng `pathcount` theo chương trình của thầy.

---

## 5. Định dạng file (bản gốc trang 7–10)

Mỗi instance gồm 3 file JSON.

### 5.1.1 Mạng: `*-net.json` (định dạng tương thích NetworkX)
- **Đầu file:** `directed` (đồ thị có hướng hay không), `multigraph` (có cho phép nhiều cạnh giữa cùng một cặp nút hay không). Đề khẳng định đồ thị **không phải multigraph**.
- **`nodes`:** `name` (nhãn), `id` (định danh duy nhất).
- **`links`:** `id`, `metric` (trọng số ω), `capacity` (dung lượng c), `from`, `to` (id nút đầu và nút cuối). Mọi id trong `from`/`to` phải có trong `nodes`.

### 5.1.2 Ma trận lưu lượng: `*-tm.json`
- **`num_time_slots`:** số thời kỳ h.
- **`demands`:** danh sách demand, mỗi phần tử có `s` (nguồn), `t` (đích), `v` (mảng lưu lượng, mỗi thời kỳ một giá trị).

### 5.1.3 Scenario: `*-scenario.json`
- **`max_segments`:** maxSeg (với setA là 6).
- **`budget`:** danh sách `{t, value}`, ngân sách β(t) của từng thời kỳ.
- **`interventions`:** danh sách `{t, links}`, các link id bị tắt ở thời kỳ t.
- **t = 0 không xuất hiện trong file:** ở t = 0 ngân sách coi như vô hạn và không có link nào bị tắt.

### 5.2 Đầu ra: `*-srpaths.json`
- **`srpaths`:** danh sách `{d, t, w}`, trong đó `d` là id demand, `t` là thời kỳ, `w` là danh sách waypoint theo thứ tự.
- **Đường đi thẳng:** khi danh sách waypoint rỗng (đi theo đường ngắn nhất), có thể bỏ hẳn dòng đó.

---

## 6. Bảng thuật ngữ (theo Phụ lục A, trang 11–12)

| Ký hiệu / thuật ngữ | Nghĩa |
|---|---|
| G = (V, A) | Đồ thị có hướng của mạng |
| ω(a), c(a) | Trọng số và dung lượng của cạnh a |
| FG(u, v) | Forwarding graph: các cạnh nằm trên đường ngắn nhất u→v |
| ECMP | Chia đều luồng tại mỗi nút cho các cạnh ra trong FG |
| waypoint | Nút trung gian bắt buộc đi qua trong segment path |
| segment (i, j) | Cặp nút liên tiếp trong segment path |
| maxSeg | Số segment tối đa trên một đường |
| D, σ(d, t) | Tập demand và lưu lượng của demand d ở thời kỳ t |
| T, T* | Tập thời kỳ; T* = T \ {0} |
| q(t), G_t | Tập cạnh bị tắt ở thời kỳ t; đồ thị còn lại |
| β(t), dist | Ngân sách thay đổi; số segment khác nhau giữa hai phương án |
| r(u, v, a, t) | Hệ số chia: tỉ lệ luồng u→v đi qua cạnh a trong G_t |
| λ(a, t) | Tải (utilization) của cạnh a ở thời kỳ t |
| MLU | Tải lớn nhất trên mọi cạnh và mọi thời kỳ |
| x^{dt}_{ij} | Biến nhị phân: demand d dùng segment (i, j) ở thời kỳ t |
| lex min | Cực tiểu theo thứ tự từ điển của vector tải sắp giảm dần |
