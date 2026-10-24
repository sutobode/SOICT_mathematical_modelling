# Giải thích kết quả cải tiến

Tài liệu này giải thích hai thí nghiệm ngoài đợt chạy chính thức, nằm trong thư mục này:

1. **Gộp biến khi ngân sách nhỏ** (`merge/`): một phép biến đổi mô hình chính xác, đã được chứng minh và kiểm chứng.
2. **Tối ưu lexicographic chính xác** (`lex/`): lần thử thất bại, kèm phân tích nguyên nhân và hướng sửa.

Danh sách file và số liệu thô nằm trong `README.md`.

---

## Phần 1. Gộp biến khi ngân sách nhỏ

### 1.1 Bối cảnh

Với P = 2, model gốc có hai bộ biến định tuyến: x^{d,0} cho t = 0 và x^{d,1} cho t = 1. Ngoài ra có biến phụ y để đo phần thay đổi, cùng ràng buộc ngân sách (4):

  Σ_d Σ_{i≠j} |x^{d,1}_{ij} − x^{d,0}_{ij}| ≤ β(1).

Với từng demand, vế trái là **dist**: số segment có ở đúng một trong hai đường, tức là cỡ của hiệu đối xứng giữa hai tập segment.

### 1.2 Bổ đề: đổi đường tốn ít nhất 3 đơn vị ngân sách

**Phát biểu.** Hai SR path hợp lệ, khác nhau, cùng đi từ s đến t thì có dist ≥ 3.

**Chứng minh.** Tại mỗi nút v, đặt bal(v) = số segment ra khỏi v − số segment vào v. Ràng buộc bảo toàn luồng buộc bal(s) = +1, bal(t) = −1, và bal(v) = 0 ở mọi nút khác. Như vậy hai đường hợp lệ có **cùng bảng cân bằng**, nên những segment bị bỏ đi và những segment được thêm vào phải bù trừ nhau tại từng nút.

- **dist = 1:** chỉ một segment (u, v) thay đổi. Cân bằng tại u và v bị lệch mà không có gì bù lại, nên không thể xảy ra.
- **dist = 2, kiểu bỏ 1 và thêm 1:** segment thêm vào phải có cùng điểm đầu và cùng điểm cuối với segment bị bỏ. Vậy hai segment là một, mâu thuẫn với việc hai đường khác nhau.
- **dist = 2, kiểu bỏ 2 hoặc thêm 2:** hai segment chỉ tự bù nhau được nếu là cặp (u, v) và (v, u). Cặp này tạo thành vòng, mà trên một đường đơn thì không thể có vòng.

Vậy dist ≥ 3. Dấu bằng đạt được, ví dụ khi chuyển ⟨s, t⟩ sang ⟨s, w, t⟩. ∎

**Hệ quả.** Gọi k là số demand đổi đường. Khi đó 3k ≤ β, tức **k ≤ ⌊β/3⌋**. Đặc biệt, nếu β < 3 thì không demand nào được đổi đường.

### 1.3 Model gộp

Khi mọi β(t) < 3, ta dùng **một** bộ biến x^{d}_{ij} chung cho mọi thời kỳ:

- Chỉ cho phép segment (i, j) nếu nó có đường đi trong **mọi** G_t.
- Bảo toàn luồng, giới hạn maxSeg và điều kiện đường đơn chỉ cần viết một lần.
- Ràng buộc tải **vẫn giữ cho mọi thời kỳ**. Mỗi thời kỳ dùng hệ số r và lưu lượng của chính nó, nhưng chung biến x.
- Bỏ hẳn biến y và ràng buộc ngân sách, vì phần thay đổi luôn bằng 0.

**Tính chính xác.**
- Mọi nghiệm của model gộp, khi sao chép x sang mọi t, đều là nghiệm của model gốc với 0 thay đổi.
- Ngược lại, theo bổ đề, mọi nghiệm của model gốc đều có x giống nhau ở mọi t, nên cũng là nghiệm của model gộp.

Vậy hai model có **cùng giá trị tối ưu**. Phép gộp này không làm mất nghiệm nào.

*Chi tiết kỹ thuật:* MILP cho phép tồn tại chu trình rời (không nối với đường s–t). Với β = 2, model gốc có thể thêm một chu trình 2 cạnh. Nhưng chu trình chỉ làm tăng tải, nên MLU tối ưu không đổi.

**Kích thước.** Model gộp có ít hơn P lần số biến x và không còn phần ngân sách. Với setA-01, số biến giảm từ 45.601 xuống 15.201 và số ràng buộc giảm từ 35.440 xuống 2.599.

### 1.4 Kết quả kiểm chứng

| Bước | Thí nghiệm | Kết quả | Ý nghĩa |
|---|---|---|---|
| 1 | Vét cạn các cặp đường (`brute.csv`) | 2,88 triệu cặp ở setA-01: dist nhỏ nhất khác 0 bằng 3, không có vi phạm | Bổ đề đúng trên dữ liệu thật |
| 2 | Model gốc so với model gộp, β = 0..3 (`equiv.csv`) | Mọi trường hợp cả hai cùng tối ưu đều cho MLU trùng nhau | Xác nhận tính chính xác |
| 2 | Tốc độ | Ví dụ setA-01 β = 1: từ 52,8 s xuống 3,9 s | Gộp biến giúp giải nhanh hơn |
| 3 | Kiểm tra độc lập (`verify_merged.csv`) | 22/22 nghiệm verified | Nghiệm hợp lệ theo đề |
| 4 | setA-05 P2, β = 1, 10 seed × 3600 s (`setA05-merged.csv`) | Hết giờ ở cả 10 seed; MLU 0,999986 bằng nghiệm khởi đầu; bound ≈ 0 | Không giúp được instance khó nhất |

Chi tiết tốc độ ở bước 2:

| Instance, β | Model gốc | Model gộp |
|---|---|---|
| setA-01, β = 1 | Optimal, 52,8 s | Optimal, 3,9 s |
| setA-01, β = 2 | Optimal, 60,3 s | Optimal, 3,9 s |
| setA-02, β = 1 | **TIME_LIMIT** sau 904 s, MLU 1,098 | **Optimal** 0,903, 7,6 s |
| setA-02, β = 2 | TIME_LIMIT sau 904 s, MLU 1,098 | Optimal 0,903, 7,6 s |
| setA-03, β = 1 | TIME_LIMIT sau 970 s, MLU 1,000 | Optimal 0,944, 60,6 s |
| setA-03, β = 2 | TIME_LIMIT sau 905 s, MLU 1,000 | Optimal 0,944, 60,4 s |

Hai nhận xét phụ:

- **β = 3 (đối chứng).** Khi β = 3, model gộp không còn chính xác, vì được phép đổi đường cho 1 demand. Ở setA-01, hai model cho kết quả bằng nhau. Ở setA-02 và setA-03, model gốc hết giờ trong khi đã đổi đường cho 1 demand (dist = 3), nhưng vẫn kém hơn nghiệm của model gộp. Vì vậy chưa kết luận được liệu việc đổi đường có giúp ích hay không.
- **Ngân sách không cần đến ở các instance nhỏ.** MLU tối ưu của model gộp bằng đúng MLU tối ưu chính thức của P2 trên setA-01..03 (khi β thật là 51/63/53). Nghĩa là trên các instance này, đến tối ưu mà không cần dùng ngân sách.

### 1.5 Vì sao không giúp được setA-05 P2

Model gộp của setA-05 có 990.001 biến, **bằng đúng P1** của setA-05, và chỉ thêm khoảng 400 ràng buộc tải cho t = 1. Thế nhưng P1 giải xong trong khoảng 150 s, còn model gộp chưa giải xong nổi LP ở nút gốc trong 3600 s: presolve mất khoảng 100 s, rồi hơn 110 nghìn vòng lặp simplex vẫn chưa xong.

~~**Kết luận:** cái khó của setA-05 P2 **không nằm ở biến ngân sách**, mà ở yêu cầu một cách định tuyến duy nhất phải tốt cho **hai topology** cùng lúc.~~

> **Đính chính (Phần 3):** giả thuyết trên **sai**. Bài toán thật ra dễ: chỉ cần đổi đường cho một demand. Model gộp bị kẹt vì hai lý do. Một là simplex quá chậm với LP gần 1 triệu cột (IPM giải xong cùng LP đó trong 347 s). Hai là nghiệm khởi đầu từ heuristic không cải thiện được gì.

### 1.6 Cách trình bày khi bảo vệ

- Bổ đề "≥ 3" và hệ quả k ≤ ⌊β/3⌋ cho thấy nhóm hiểu cấu trúc ràng buộc ngân sách.
- Model gộp là một phép biến đổi **chính xác**, đã có chứng minh và kiểm chứng bằng máy. Nó tăng tốc mạnh ở các instance vừa với β nhỏ.
- Kết quả âm tính trên setA-05 được nêu thẳng, vì nó chỉ ra đúng nguồn gốc của độ khó.
- Ý tưởng chưa thử: với β ≥ 3, thêm ràng buộc hợp lệ "số demand đổi đường ≤ ⌊β/3⌋" (cần một biến nhị phân cho mỗi demand) để làm chặt model.

---

## Phần 2. Tối ưu lexicographic chính xác

### 2.1 Đã chạy gì

`lex/lex.sh` gọi `orange/scripts/run_lex_pathcount.jl`, không sửa gì, theo thứ tự setA-01 P1, setA-01 P2, setA-02 P1. Hạn chót chung cho cả chuỗi là 14 giờ.

| Run | Số link L | Biến nhị phân thêm vào | Giới hạn mỗi hạng | Kết quả |
|---|---|---|---|---|
| setA-01 P1 | 80 | 6.400 | 1800 s | Hạng 1 TIME_LIMIT, dừng sau 33 phút |
| setA-01 P2 | 159 | 25.281 | 3600 s | Hạng 1 TIME_LIMIT, dừng sau 83 phút |
| setA-02 P1 | 150 | 22.500 | 1800 s | Hạng 1 TIME_LIMIT, dừng sau 47 phút |

Không run nào tạo ra nghiệm lex. Chuỗi kết thúc sớm, còn dư khoảng 11 giờ so với hạn chót.

### 2.2 Công thức hiện tại

Hàm `exact_lexicographic_loads!` (`orange/src/model.jl`) thêm vào model:

- **Biến hạng.** ranks[1] ≥ ranks[2] ≥ … ≥ ranks[L], trong đó ranks[k] là utilization lớn thứ k.
- **Biến gán hạng.** a[e,k] ∈ {0, 1}, bằng 1 khi link e đứng ở hạng k. Mỗi link nhận đúng một hạng và mỗi hạng có đúng một link.
- **Ràng buộc big-M.** |ranks[k] − util[e]| ≤ M·(1 − a[e,k]).
- **Quy trình giải.** Tối ưu ranks[1], cố định giá trị, rồi tối ưu ranks[2], và cứ thế đến ranks[L]. Mỗi hạng phải đạt OPTIMAL với gap = 0.

### 2.3 Vì sao quá yếu

1. **LP nới lỏng vô dụng.** Solver có thể đặt a[e,k] = 1/L cho mọi cặp, khi đó ràng buộc big-M gần như không còn tác dụng. Lại không có ràng buộc ranks[1] ≥ util[e], nên cận dưới ≈ 0. Ngược lại, bài min MLU gốc có z ≥ util[e] cho mọi link, nên cận chặt ngay từ đầu. Đây là lý do hạng 1 (thực chất cũng là MLU) không giải nổi, trong khi bài min MLU giải được.
2. **M lớn.** M được lấy bằng tải tối đa có thể (khi mọi x = 1), lớn hơn nhiều so với MLU thật. M càng lớn thì LP càng lỏng.
3. **Đối xứng.** Nhiều link có tải bằng nhau, nên hoán đổi hạng giữa chúng tạo ra vô số nghiệm tương đương. Branch-and-bound phải duyệt lại các nhánh giống nhau.
4. **Model phình to.** Thêm L² biến nhị phân. Ngoài ra `acyclic=true` thêm ràng buộc MTZ (cũng là big-M).
5. **Quá nhiều lần giải, và không chừa đường lui.** Cần L lần giải MILP (80 đến 159 lần). Chỉ một hạng hết giờ là mất toàn bộ run.

### 2.4 Hướng sửa

- **Sửa nhanh:** thêm các ràng buộc hợp lệ ranks[1] ≥ util[e] với mọi e, và Σ_k ranks[k] = Σ_e util[e]. Dùng nghiệm min MLU làm warm start.
- **Sửa tận gốc (k-sum/OWA):** gọi θ_k là tổng k utilization lớn nhất. Có thể viết θ_k chỉ bằng biến liên tục:

  θ_k = min k·r + Σ_e d_e, với d_e ≥ util[e] − r và d_e ≥ 0.

  Tối ưu lần lượt θ_1, θ_2, … (sau mỗi bước cố định θ_k) cho ra cùng nghiệm lex như công thức sắp xếp. Công thức này không cần biến gán hạng hay big-M, θ_1 chính là MLU, và có thể dừng sau vài hạng đầu mà vẫn có kết quả từng phần.

---

## Phần 3. Giải tối ưu setA-05 P2 (`setA05_bound/`)

### 3.1 0,99999 đến từ đâu

`bottleneck.jl` liệt kê các link nghẽn nhất khi mọi demand đi thẳng (baseline):

- Ở t = 1, lưu lượng của **demand 19 (84 → 25)** tăng từ 0,957 lên **2,872**, đúng bằng dung lượng của link trực tiếp 84 → 25. Nếu demand này đi thẳng thì link đầy 100%.
- Mọi link khác đều có utilization ≤ 0,205.

### 3.2 Nghiệm tối ưu

`fix05.jl` thử mọi đường có 1 hoặc 2 waypoint cho demand 19, dùng **cùng một đường cho cả hai thời kỳ**:

- Đường tốt nhất là ⟨84, 99, 25⟩. Ngân sách dùng 0 ≤ κ = 1.
- MLU = **0,2049858752**: ở t = 0 cao nhất 0,167 (link 40 → 73), ở t = 1 cao nhất 0,205 (link 17 → 14).
- Bộ kiểm tra độc lập: `problems: []`.

### 3.3 Chứng minh tối ưu, không cần solver

Ở t = 1, nút 17 chỉ có **một** link đi ra (17 → 14, dung lượng 26,465). Mọi demand xuất phát từ nút 17 (tổng 5,425) đều buộc phải đi qua link này, dù chọn waypoint nào. Vì vậy, với mọi cách định tuyến:

  MLU ≥ 5,425 / 26,465 = **0,2049858** = giá trị đạt được.

Có thêm hai cách xác nhận cho ra đúng số này:

- **Link bắt buộc:** bỏ link 17 → 14 thì các demand trên không còn đường đi (`bottleneck.txt`).
- **LP nới lỏng của model gộp, giải bằng IPM:** 0,2049858753 sau 347 s (`lpbound.csv`). Lần chạy bằng PDLP (`lp-pdlp.log`) chưa xong khi tải kết quả về.

Cùng lập luận này giải thích setA-05 P1: nút 83 nhận 3,191 đơn vị qua các link đi vào có tổng dung lượng 27,624, nên MLU ≥ 0,1155237, bằng đúng tối ưu chính thức.

### 3.4 Vì sao đợt chạy chính thức bỏ sót

- **`local_search` chỉ đổi đường ở một thời kỳ mỗi bước.** Với κ = 1, mọi bước như vậy tốn ≥ 3 (bổ đề Phần 1), nên đều bị từ chối. Heuristic trả về đường thẳng, MLU 0,99999. Bước cần thiết là đổi **đồng thời** cả hai thời kỳ, tốn 0 ngân sách, nhưng chưa bao giờ được thử.
- **MILP không giải xong LP nút gốc** bằng simplex trong 3600 s, nên các heuristic bên trong solver không kịp chạy.

### 3.5 Đã sửa

`orange/src/heuristic.jl`: với mỗi ứng viên, nếu đổi riêng một thời kỳ không được thì thử đổi **cùng lúc mọi thời kỳ**. Ngân sách được kiểm tra cho mọi bước chuyển bị ảnh hưởng.

- setA-05 P2: **0,2049858752 trong 1,8 s**.
- setA-05 P1: 0,1155237, bằng tối ưu.
- Test mới trên toy với ngân sách 0: heuristic phải đạt đúng tối ưu vét cạn.

Kết quả chính thức trong `report/` **không sửa**. Phân tích này được ghi riêng trong `report/setA05_P2_supplementary_analysis.md`.

---

## Tóm tắt

| Thí nghiệm | Kết luận |
|---|---|
| Bổ đề dist ≥ 3 | ✅ Đã chứng minh và kiểm chứng bằng máy |
| Model gộp khi β < 3 | ✅ Chính xác; nhanh hơn rõ rệt ở setA-01..03 |
| Model gộp + simplex trên setA-05 P2 | ❌ LP nút gốc không xong. Với IPM, cùng LP đó xong trong 347 s và cho cận 0,20499 |
| **setA-05 P2** | ✅ **Tối ưu 0,2049858752, đã chứng minh**. Trước đây là 0,99999 với gap 90% |
| Heuristic `local_search` | ✅ Đã sửa: thêm bước đổi cùng lúc mọi thời kỳ |
| Lex bằng công thức sắp xếp | ❌ Thất bại ở hạng 1 vì LP nới lỏng yếu |
| Lex bằng k-sum | Chưa thử; là hướng đề xuất |
