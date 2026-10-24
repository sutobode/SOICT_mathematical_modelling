# Kết quả cải tiến (ngoài đợt chạy chính thức), 2026-10-23/24

Chạy trên server 10.0.12.30, thư mục `/home/darkweb/network-model-test`, code ở commit `0da1a52` cộng bản vá time-budget (nhánh `fix/time-budget-status`).
Các kết quả ở đây **không thuộc** bộ kết quả chính thức trong `report/`.

## 1. `merge/`: kiểm chứng giả thuyết gộp biến

**Giả thuyết.**
- Hai SR path khác nhau của cùng một demand lệch nhau ít nhất 3 segment, nên số demand được đổi đường ≤ ⌊β/3⌋.
- Khi β(t) < 3, mọi demand phải giữ nguyên đường ở mọi thời kỳ. Vì vậy có thể dùng một bộ biến x chung cho mọi t và bỏ biến y cùng ràng buộc ngân sách. Đây là phép biến đổi chính xác.

Script: `merge/merge_check.jl`, chạy bằng `julia --project=orange merge_check.jl <brute|equiv|setA05> <outdir> ...`.

| File | Nội dung | Kết quả |
|---|---|---|
| `brute.csv` | Bước 1: vét cạn khoảng cách giữa các cặp đường | toy: 37.475 cặp; setA-01: 2.882.574 cặp. Khoảng cách nhỏ nhất khác 0 bằng **3**, không có vi phạm |
| `equiv.csv` | Bước 2: so sánh model gốc với model gộp trên setA-01..03, P = 2, β ∈ {0,1,2,3}, 900 s mỗi lần giải | Khi cả hai cùng tối ưu, MLU trùng khớp. Model gốc hết giờ ở setA-02 và setA-03 với β = 1, 2, còn model gộp chứng minh tối ưu trong 7,6 s và khoảng 60 s. Kích thước setA-01 giảm từ 45.601 biến / 35.440 ràng buộc xuống 15.201 / 2.599 |
| `verify_merged.csv` | Bước 3: kiểm tra độc lập bằng `verify_srpaths.py` | 22/22 nghiệm **verified** |
| `setA05-merged.csv`, `setA-05-P2-merged-seed*.log` | Bước 4: setA-05 P2 (β = 1) với model gộp, 10 seed, 3600 s mỗi seed | Cả 10 seed đều TIME_LIMIT. MLU 0,999986 bằng nghiệm khởi đầu; bound bằng 0 (seed 7: 0,205); 0 node. **Không cải thiện được** |
| `*-srpaths.json`, `*-loads.csv` | Nghiệm và tải từng link | |

Ghi chú về β = 3 (đối chứng): model gộp lúc đó không còn chính xác. Trên setA-01 hai model cho kết quả bằng nhau; trên setA-02 và setA-03 model gốc hết giờ nên chưa kết luận được.

## 1b. `setA05_bound/`: giải tối ưu setA-05 P2

| File | Nội dung |
|---|---|
| `bottleneck.jl`, `bottleneck.txt` | Cận dưới MLU không phụ thuộc cách định tuyến (cắt quanh nút, link bắt buộc) và các link nghẽn nhất của baseline. t = 0: 0,1155237. t = 1: **0,2049858** |
| `lpbound.jl`, `lpbound.csv`, `lp-*.log` | LP nới lỏng của model gộp. IPM: OPTIMAL 0,2049858753 sau 347 s. PDLP chưa xong khi tải về |
| `fix05.jl`, `fix05.out` | Đổi đường cho demand 19 thành ⟨84, 99, 25⟩ ở cả hai thời kỳ. MLU **0,2049858752**, bằng cận dưới, nên tối ưu. Bộ kiểm tra độc lập: OK |
| `setA-05-P2-reroute-*` | Nghiệm và tải từng link |

## 2. `lex/`: tối ưu lexicographic chính xác

Driver `lex/lex.sh` gọi `orange/scripts/run_lex_pathcount.jl` (không sửa gì) cho setA-01 P1 (1800 s mỗi hạng), setA-01 P2 (3600 s mỗi hạng) và setA-02 P1 (1800 s mỗi hạng).

**Kết quả:** cả 3 run đều thất bại ngay ở hạng 1 (`lexicographic rank 1 was not optimal: TIME_LIMIT`, xem `lex/*.out` và `lex/lex.log`). Không có nghiệm lex nào.

**Nguyên nhân:** công thức sắp xếp trong `exact_lexicographic_loads!` dùng L² biến nhị phân gán hạng cùng ràng buộc big-M.
- Khi nới lỏng LP, các biến gán hạng có thể nhận giá trị phân số 1/L, làm ràng buộc big-M mất tác dụng. Vì vậy cận dưới ≈ 0.
- Không có ràng buộc ranks[1] ≥ util[e].
- Nhiều link có tải bằng nhau tạo ra rất nhiều nghiệm đối xứng.

**Hướng sửa:** dùng công thức k-sum/OWA, chỉ cần biến liên tục, không cần biến gán hạng.
