# Báo cáo kết quả thực nghiệm T-ASR (Orange ROADEF 2026)

*Ngày lập: 24/10/2026. Số liệu lấy từ `report/` (dựng tự động từ dữ liệu thô `server_results_2026-10-24_v4/`) và `improvement_results_2026-10-24/`.*

## Tóm tắt

- **Phạm vi chạy:** 12 cấu hình × 10 run, tổng cộng 120 run. Cả 120 run đều qua bộ kiểm tra độc lập `verify_srpaths.py`.
  - Mô hình đầy đủ: setA-01..05, với P1 (1800 s) và P2 (3600 s).
  - Mô hình thu gọn: setA-10 P1 và setA-07 P2.
- **Kết quả:** 8/10 cấu hình mô hình đầy đủ được **chứng minh tối ưu**. Hai cấu hình còn lại (setA-04 P1 và P2) có nghiệm hợp lệ, gap 20,3% và 1,3%.
- **Cải tiến quan trọng nhất: setA-05 P2.**
  - Lúc đầu kẹt ở MLU 0,99999 (bằng baseline, gap 90%).
  - Phân tích cấu trúc đã tìm ra và chứng minh nghiệm tối ưu **0,2049858752**.
  - Đã sửa heuristic khởi đầu và chạy lại chính thức: cấu hình đạt **Optimal**, giảm 79,5% so với baseline.
- **Kết quả lý thuyết:** đã chứng minh và kiểm chứng bằng máy rằng hai SR path khác nhau luôn lệch nhau ≥ 3 segment. Hệ quả: khi ngân sách κ < 3, có thể gộp biến của mọi thời kỳ thành một bộ mà vẫn chính xác (model gộp).
- **Lexicographic:** công thức sắp xếp có sẵn trong code thất bại ngay ở hạng 1. Báo cáo phân tích nguyên nhân và đề xuất công thức k-sum.

---

## 1. Bài toán

**T-ASR (Time-dependent Adaptive Segment Routing).**
- Mỗi demand d (nguồn s, đích t, lưu lượng σ(d, t)) được gán một **SR path** ⟨s, w₁, …, t⟩.
- Giữa hai điểm liên tiếp, lưu lượng đi theo các đường ngắn nhất và được chia theo hệ số **r**. Dự án dùng cách chia *path-count* r = σ_ix·σ_yj/σ_ij, theo tài liệu `calculating_r.pdf` của môn học.

**Mô hình MILP.**
- Biến x^{dt}_{ij} ∈ {0, 1} cho biết demand d ở thời kỳ t có dùng segment (i, j) hay không. Biến z là MLU.
- Các ràng buộc:
  1. bảo toàn luồng;
  2. tối đa maxSeg = 6 segment;
  3. tải: Σ r·σ·x ≤ z·c(a) với mọi link a đang hoạt động;
  4. ngân sách: Σ_d Σ_{ij} |x^{dt} − x^{d,t−1}| ≤ κ(t).
- Mục tiêu chính thức: **min z (MLU thuần)**. Đây là thành phần đầu tiên của mục tiêu lexicographic (5) trong đề.

**Hai kịch bản.**
- P1: chỉ t = 0.
- P2: t = 0 và t = 1. Ở t = 1 có **một link bị tắt** và lưu lượng thay đổi. Ràng buộc ngân sách κ(1) giới hạn mức thay đổi định tuyến giữa hai thời kỳ.

## 2. Bộ dữ liệu

| Bộ | Nút | Link | Demand | κ(1) | Cột HiGHS P1 | Cột HiGHS P2 | Mô hình đã chạy |
|---|---|---|---|---|---|---|---|
| setA-01 | 20 | 80 | 40 | 51 | 15.201 | 45.601 | đầy đủ, P1 và P2 |
| setA-02 | 30 | 150 | 45 | 63 | 39.151 | 117.451 | đầy đủ, P1 và P2 |
| setA-03 | 50 | 250 | 20 | 53 | 49.001 | 147.001 | đầy đủ, P1 và P2 |
| setA-04 | 50 | 250 | 200 | 44 | 490.001 | 1.470.001 | đầy đủ, P1 và P2 |
| setA-05 | 100 | 396 | 100 | **1** | 990.001 | 2.970.001 | đầy đủ, P1 và P2 |
| setA-07 | 100 | 500 | 800 | – | (15,8 triệu biến x) | | thu gọn, P2 (K = 98) |
| setA-10 | 150 | 966 | 1000 | – | (22,4 triệu biến x) | | thu gọn, P1 (K = 148) |

Số biến x = |D|·P·n(n−1). setA-07 và setA-10 vượt quá RAM nếu dùng mô hình đầy đủ, nên được chạy bằng mô hình waypoint thu gọn. Mô hình này chỉ cho **cận trên** của bài toán gốc.

## 3. Thiết lập thực nghiệm

| Hạng mục | Giá trị |
|---|---|
| Máy | VM Ubuntu 24.04, Xeon Silver 4314 (16 vCPU), 125 GiB RAM |
| Phần mềm | Julia 1.13.1, JuMP 1.32.1, HiGHS 1.15.1 |
| Giao thức | 10 run mỗi cấu hình (`random_seed` = số thứ tự run), 1 luồng mỗi run, `mip_rel_gap` = 1e-6; giới hạn 1800 s (P1) và 3600 s (P2) |
| Nghiệm khởi đầu | heuristic `local_search` (tìm kiếm cục bộ quanh link nghẽn nhất), giới hạn 30 s |
| Baseline | mọi demand đi thẳng ⟨s, t⟩, không dùng waypoint |
| Kiểm tra | `verify_srpaths.py` tự tính lại tải, MLU và ngân sách từ file nghiệm, độc lập với solver: **120/120 verified** |
| Kiểm soát thời gian | đo bằng đồng hồ đơn điệu cộng callback HiGHS. Nếu solver chạy lố trong pha không gọi callback, kết quả được cắt về trạng thái tại thời điểm hết hạn. Không có run nào vi phạm giao thức. |
| Phiên bản code | 100 run trên `0da1a52`; setA-04 P2 trên `0da1a52` + bản vá time-budget (`ff5040ef`); setA-05 P2 thêm bản vá heuristic (`2a7b3841`) |

## 4. Kết quả chính thức

### 4.1 P1 (một thời kỳ, 1800 s)

| Bộ | Baseline | **MLU** | Cận dưới | Cải thiện | Trạng thái | Thời gian TB / trung vị (s) |
|---|---|---|---|---|---|---|
| setA-01 | 1,0000 | **0,92938** | 0,92938 | 7,1% | Optimal 10/10 | 0,7 / 0,7 |
| setA-02 | 1,0000 | **0,54858** | 0,54858 | 45,1% | Optimal 10/10 | 3,7 / 3,4 |
| setA-03 | 1,0000 | **0,94354** | 0,94354 | 5,6% | Optimal 10/10 | 32 / 5 |
| setA-04 | 0,6918 | **0,51828** | 0,45907 | 25,1% | Feasible, gap TB 20,3% | 1800 / 1800 |
| setA-05 | 0,3333 | **0,11552** | 0,11552 | 65,3% | Optimal 10/10 | 149 / 145 |
| setA-10 (thu gọn) | 1,0000 | **0,07120** | – | 92,9% | cận trên | 1801 / 1801 |

### 4.2 P2 (hai thời kỳ, link bị tắt ở t = 1, 3600 s)

| Bộ | Baseline | **MLU** | Cận dưới | Cải thiện | Trạng thái | Thời gian TB / trung vị (s) |
|---|---|---|---|---|---|---|
| setA-01 | 1,0000 | **0,92938** | 0,92938 | 7,1% | Optimal 10/10 | 20,8 / 20,8 |
| setA-02 | 1,0981 | **0,90307** | 0,90307 | 17,8% | Optimal (chứng minh ở 4/10 run) | 2235 / 3600 |
| setA-03 | 1,0000 | **0,94354** | 0,94354 | 5,6% | Optimal 10/10 | 760 / 727 |
| setA-04 | 1,0000 | **0,58857** | 0,58114 | 41,1% | Feasible, gap 1,3% | 3601 / 3601 |
| setA-05 | 0,99999 | **0,20499** | 0,20499 | 79,5% | Optimal (chứng minh ở 5/10 run) | 1880 / 1895 |
| setA-07 (thu gọn) | 1,0000 | **0,90799** | – | 9,2% | cận trên | 81 / 81 |

### 4.3 Nhận xét

1. **Waypoint giúp giảm MLU đáng kể**, từ 5,6% (setA-03) đến 79,5% (setA-05 P2). Mức giảm phụ thuộc mạnh vào cấu trúc mạng: khi nghẽn nằm ở một nút không có lối vòng, waypoint gần như không giúp được gì.
2. **MLU của P2 luôn ≥ P1**, vì mạng mất một link và lưu lượng ở t = 1 thay đổi. Ví dụ setA-02 tăng từ 0,549 lên 0,903; setA-05 tăng từ 0,116 lên 0,205.
3. **P2 khó hơn P1 rất nhiều.** Số cột gấp khoảng 3 lần (thêm x cho t = 1 và biến y của ngân sách). Ví dụ thời gian giải setA-03 tăng từ 32 s lên 760 s; setA-02 P2 chỉ chứng minh tối ưu được ở 4/10 run.
4. **Độ khó tăng theo |D|·n².** setA-04 (200 demand) là bộ duy nhất không chứng minh được tối ưu, kể cả ở P1, dù có ít nút hơn setA-05.
5. **MILP chủ yếu chứng minh tối ưu cho nghiệm heuristic.** Trong cả 100 run mô hình đầy đủ, nghiệm cuối cùng chính là nghiệm khởi đầu từ `local_search`. Solver đóng góp cận dưới và chứng minh tối ưu, chứ không tìm ra nghiệm tốt hơn trong thời gian cho phép.
6. **Kết quả phụ thuộc vào seed** (performance variability). Trên setA-05 P2, với cùng model và cùng nghiệm khởi đầu tối ưu, LP nút gốc giải xong sau 1.665 vòng lặp simplex với seed 2, nhưng sau 32.146 vòng lặp vẫn chưa xong với seed 1.

## 5. Cải tiến 1: bổ đề "≥ 3" và model gộp biến

### 5.1 Bổ đề

**Phát biểu.** Hai SR path hợp lệ, khác nhau, cùng đi từ s đến t thì có dist ≥ 3, với dist là số segment có ở đúng một trong hai đường.

**Chứng minh (cân bằng nút).** Tại mỗi nút, đặt hiệu "số segment ra − số segment vào". Mọi đường hợp lệ có cùng bảng hiệu này: +1 tại s, −1 tại t, 0 tại các nút khác.
- Đổi 1 segment làm lệch cân bằng tại hai đầu của nó, nên không thể xảy ra.
- Bỏ 1 và thêm 1: segment mới phải có cùng điểm đầu và điểm cuối với segment bị bỏ, tức là trùng nhau.
- Thêm 2 hoặc bỏ 2: chỉ có thể là một vòng u → v → u, mà đường đơn không chứa vòng.

**Hệ quả.** Số demand đổi đường giữa t−1 và t ≤ ⌊κ(t)/3⌋. Riêng **κ < 3 thì không demand nào được đổi đường.**

**Kiểm chứng bằng máy:** vét cạn 2.882.574 cặp đường của setA-01 cho khoảng cách nhỏ nhất khác 0 đúng bằng 3, không có vi phạm.

### 5.2 Model gộp

Khi κ < 3, dùng **một** bộ biến x^{d}_{ij} cho mọi thời kỳ:
- Ràng buộc đường đi chỉ viết một lần.
- Ràng buộc tải giữ cho từng thời kỳ.
- Chỉ cho phép segment đi được trong mọi G_t.
- Bỏ biến y và ràng buộc ngân sách.

Phép biến đổi này **chính xác**: hai model có cùng tập nghiệm (chứng minh hai chiều), và số biến giảm P lần.

**So sánh với model gốc** (P2, ghi đè κ, 900 s mỗi lần giải):

| Bộ, κ | Model gốc | Model gộp | Kích thước (biến): gốc → gộp |
|---|---|---|---|
| setA-01, κ = 1 | Optimal 0,92938, 52,8 s | Optimal 0,92938, **3,9 s** | 45.601 → 15.201 |
| setA-02, κ = 1 | **TIME_LIMIT**, MLU 1,098 | **Optimal 0,90307, 7,6 s** | 117.451 → 39.151 |
| setA-03, κ = 1 | **TIME_LIMIT**, MLU 1,000 | **Optimal 0,94354, 60,6 s** | 147.001 → 49.001 |

- Ở mọi trường hợp cả hai model cùng giải tới tối ưu (5 cặp), MLU trùng nhau.
- 22/22 nghiệm của model gộp qua bộ kiểm tra độc lập.

**Phát hiện thêm:** trên setA-01..03, MLU tối ưu của model gộp bằng đúng tối ưu P2 chính thức (với κ thật là 51–63). Nghĩa là ở các bộ này, đổi đường giữa hai thời kỳ không giúp giảm MLU.

## 6. Cải tiến 2: giải tối ưu setA-05 P2

### 6.1 Vấn đề

Trong lần chạy chính thức trước, cả 10 run của setA-05 P2 đều dừng ở MLU 0,99999 (bằng baseline), gap 90%. Phân tích cho thấy nguyên nhân gồm ba điểm:

- **Cái bẫy trong dữ liệu.** Ở t = 1, lưu lượng của demand 19 (84 → 25) tăng lên 2,872, **đúng bằng dung lượng** của link trực tiếp 84 → 25. Nếu demand này đi thẳng thì link đầy 100%.
- **Heuristic bị kẹt.** `local_search` mỗi bước chỉ đổi đường ở **một** thời kỳ. Với κ = 1, mọi bước như vậy tốn ≥ 3 (theo bổ đề), nên đều bị từ chối và heuristic trả về baseline.
- **Solver không cứu được.** Với 2,97 triệu cột (presolve tắt), HiGHS không giải xong LP nút gốc, nên các heuristic bên trong solver không kịp chạy.

### 6.2 Lời giải và chứng minh

- **Nghiệm.** Cho demand 19 đi qua waypoint 99, đường ⟨84, 99, 25⟩, **ở cả hai thời kỳ**, nên tốn 0 ngân sách. MLU = **0,2049858752**; utilization lớn nhất là 0,167 ở t = 0 và 0,205 ở t = 1 (link 17 → 14).
- **Chứng minh tối ưu, không cần solver.** Ở t = 1, nút 17 chỉ có **một** link đi ra (17 → 14, dung lượng 26,465). Các demand xuất phát từ nút 17 (tổng 5,425) buộc phải đi qua link này, nên MLU ≥ 5,425 / 26,465 = 0,2049858 với mọi cách định tuyến.
- **Xác nhận thêm.** LP nới lỏng của model gộp, giải bằng IPM, cho đúng cận 0,2049858753 sau 347 s. PDLP thì không hội tụ trong 7200 s.
- **Ghi chú về P1.** Cùng lập luận giải thích setA-05 P1: nút 83 nhận 3,191 đơn vị qua các link đi vào có tổng dung lượng 27,624, nên MLU ≥ 0,1155237, bằng đúng tối ưu.

### 6.3 Sửa heuristic và chạy lại chính thức

`local_search` được bổ sung bước **"đổi đồng thời mọi thời kỳ"**, có kiểm tra ngân sách cho mọi bước chuyển bị ảnh hưởng. Có thêm test: trên toy với ngân sách 0, heuristic phải đạt đúng tối ưu vét cạn. Kết quả là heuristic đạt 0,20499 trong **1,8 s**.

Chạy lại chính thức 10 run (cùng giao thức; 5 tiến trình song song):

| Seed | Trạng thái | MLU | Thời gian |
|---|---|---|---|
| 2, 3, 6, 7, 10 | **Optimal** | 0,2049858752 | 120–189 s |
| 1, 4, 5, 8, 9 | hết giờ (LP nút gốc chưa xong, cận dưới 0) | 0,2049858752 | 3600 s |

## 7. Lexicographic

**Đã thử:** `exact_lexicographic_loads!` trên setA-01 P1, setA-01 P2 và setA-02 P1. Cả ba **thất bại ngay ở hạng 1** vì hết giờ (1800 s hoặc 3600 s), trong khi bài min MLU tương đương được giải xong rất nhanh.

**Nguyên nhân** nằm ở công thức sắp xếp, gồm L² biến gán hạng và ràng buộc big-M:
- Khi nới lỏng LP, biến gán hạng có thể nhận giá trị 1/L, làm ràng buộc big-M mất tác dụng, nên cận dưới ≈ 0.
- Không có ràng buộc hạng 1 ≥ tải của mọi link.
- M lớn, cộng với rất nhiều nghiệm đối xứng (các link có tải bằng nhau).
- Cần L lần giải MILP liên tiếp (80–159 lần), mà chỉ một lần hết giờ là mất toàn bộ run.

**Đề xuất:** công thức k-sum (OWA), với θ_k = min k·r + Σ_e max(0, util_e − r), tức tổng k utilization lớn nhất. Công thức này chỉ dùng biến liên tục, không cần biến gán hạng hay big-M; θ_1 chính là MLU, và có thể dừng sau vài hạng đầu mà vẫn có kết quả từng phần.

## 8. Hạn chế

- **Hệ số r** theo cách chia path-count của môn học. Cách này khác với ECMP chia đều tại từng nút như mô tả trong đề, khi các nhánh có số đường ngắn nhất khác nhau.
- **Mục tiêu chính thức chỉ là MLU thuần.** Lexicographic chưa có kết quả.
- **Mô hình đầy đủ chỉ chạy được tới khoảng 3 triệu cột** (setA-01..05). setA-07 và setA-10 chỉ có cận trên từ mô hình thu gọn.
- **Kết quả đến từ ba phiên bản code** (ghi rõ trong cột `code_version`). Bản sửa heuristic có thể cải thiện thêm các cấu hình P2 khác, nhưng mới chỉ chạy lại setA-05 P2.
- **Môi trường dùng chung.** Chạy trên VM dùng chung; lần chạy lại setA-05 P2 dùng 5 tiến trình song song, nên thời gian có thể hơi bị kéo dài.
- **setA-04** (P1 gap 20%, P2 gap 1,3%) chưa được chứng minh tối ưu.

## 9. Hướng phát triển

1. Giải LP nút gốc bằng **IPM** thay vì simplex: IPM giải LP của model gộp setA-05 trong 347 s, và ít phụ thuộc seed hơn.
2. Thêm các cận tổ hợp (cắt quanh nút, link bắt buộc) và ràng buộc hợp lệ "số demand đổi đường ≤ ⌊κ/3⌋" vào mô hình để làm chặt cận.
3. Cài đặt lexicographic theo k-sum, chạy trước trên setA-01.
4. Chạy lại các cấu hình P2 khác với heuristic mới; dùng model gộp làm heuristic cho setA-04.
5. Sinh cột (column generation) cho các bộ lớn setA-06..20.

## 10. Tái lập và bằng chứng

| Nội dung | Vị trí |
|---|---|
| Kết quả từng run / từng cấu hình | `report/final_run_level_results.csv`, `report/final_configuration_summary.csv` |
| Audit đầy đủ (code, thời gian, trạng thái) | `report/experiment_audit.md` |
| Gói bằng chứng (log, patch, bảng đã sinh) | `report/experiment_evidence/`, `report/experiment_evidence.zip` |
| Phân tích setA-05 P2 (tiếng Anh) | `report/setA05_P2_supplementary_analysis.md` |
| Dữ liệu thô của đợt chạy | `server_results_2026-10-24_v4/` |
| Thí nghiệm cải tiến (model gộp, lex, setA-05) | `improvement_results_2026-10-24/` (giải thích: `GIAI_THICH_KET_QUA_CAI_TIEN.md`) |
| Code | `orange/` (nhánh `kien`); bản vá heuristic ở commit `2b3f85b` |
