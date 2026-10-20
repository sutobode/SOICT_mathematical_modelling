# Việc code (không bắt buộc) giao cho coding agent — chỉ làm sau khi xong phần chạy thực nghiệm

> Ưu tiên của nhóm: **yêu cầu tối thiểu của thầy trước** (các lần chạy ở `M2_BRIEF.md`, `M3_BRIEF.md`). Chỉ giao việc dưới đây khi một thành viên đã xong phần chạy và còn thời gian trước T4. Khác với các brief chạy thực nghiệm, các việc này **được phép tạo/sửa đúng các file nêu tên** (trên bản sao thư mục), không được dùng git.

## Quy tắc chung cho việc code

1. Làm việc trên **bản sao** của thư mục dự án (ví dụ `C:\soict_code`), không làm trên thư mục đang chạy thực nghiệm.
2. Chỉ được sửa/tạo **đúng các file nêu trong từng việc**. Không đổi chữ ký hàm công khai; không đổi định dạng CSV.
3. **TDD bắt buộc:** viết test trước, chạy để thấy test **thất bại đúng lý do**, rồi mới viết mã; cuối cùng chạy `julia --project=orange orange/test/runtests.jl` và **toàn bộ bộ test phải đạt** (không có `Fail`/`Error`).
4. Không dùng git. Kết quả giao nộp: các file đã sửa/tạo (chép vào thư mục `member_results/code_<tên>/`) và một đoạn tóm tắt: đã đổi gì, vì sao, test nào mới, kết quả bộ test, tác động lên số liệu (nếu có).
5. Mã mới phải có chú thích ngắn bằng tiếng Việt giống phong cách mã hiện có.
6. Dừng và hỏi người điều phối nếu việc đòi hỏi sửa file ngoài danh sách.

## Việc C1 — Heuristic không bị kẹt khi nhiều cung cùng tải lớn nhất

- **Vấn đề:** `local_search` (file `orange/src/heuristic.jl`) chỉ nhận một nước đi nếu **MLU toàn cục giảm thực sự**. Khi có nhiều cung cùng đạt mức tải lớn nhất (rất thường gặp với ECMP đối xứng), không nước đi đơn lẻ nào làm giảm MLU nên thuật toán dừng ngay, ví dụ setA-10 với $t=0,1$ giữ nguyên mức cơ sở 1,0.
- **Hướng giải:** so sánh theo **thứ tự từ điển** của vector tải đã sắp giảm dần (đã có hàm `lex_leq` trong `orange/src/verify.jl`) thay cho chỉ MLU: nhận nước đi nếu nó làm vector tải **giảm theo thứ tự từ điển** (ví dụ giảm số cung đạt mức tối đa). Giữ nguyên ràng buộc ngân sách và maxSeg.
- **File được phép:** `orange/src/heuristic.jl`; test mới trong file riêng `orange/test/test_heuristic_ties.jl` (người điều phối sẽ đưa vào `runtests.jl`).
- **Tiêu chí hoàn thành:**
  1. Một test dựng instance nhỏ (có thể dùng `orange/test/toy`) có hai demand cùng tạo hai cung tải bằng nhau ở mức tối đa; heuristic cũ không cải thiện, heuristic mới cải thiện (hoặc không tệ hơn và vector tải sắp xếp giảm theo thứ tự từ điển).
  2. Test hiện có (`local search`, `LNS`, ...) vẫn đạt; nghiệm luôn tôn trọng ngân sách (`check_solution(...).budget_ok == true`).
  3. Báo cáo: MLU trước/sau của heuristic trên toy với $P=1$ và $P=2$, và trên `setA-02`, `setA-10` ($P=2$) nếu chạy được.

## Việc C2 — Chạy LNS cho các dòng Bảng 2 có nghiệm yếu (chỉ chạy lệnh, không sửa code)

- **Vấn đề:** ở Bảng 2 một số dòng waypoint có MLU gần mức cơ sở (ví dụ setA-18 = 1,0; setA-07 = 0,908; setA-20 = 0,991); chưa biết đó là điểm nghẽn thật hay chưa tối ưu.
- **Việc:** chạy đường nhanh (bỏ MILP, sinh cột thời kỳ đầu, rồi LNS) cho từng instance và so sánh MLU với dòng hiện có. Mỗi instance, **một tiến trình tại một thời điểm**, chạy nền, nhật ký ghi vào `orange/results/log-wp-fast-P2-<instance>.txt`:
  ```bash
  julia --project=orange orange/scripts/run_wp.jl 2 3600 <i> <i> 1500000 cg ecmp lns 1800 fast
  ```
  với `<i>` lần lượt là `18`, `7`, `20`. Mỗi instance mất khoảng 10–40 phút (tuỳ kích thước). Kết quả: `orange/results/setA-XX-wp-P2-cg-lns-fast.csv` và `...-srpaths.json`.
- **Kiểm tra:** `python -I orange/scripts/verify_srpaths.py setA-18-wp-P2-cg-lns-fast` phải báo không có vấn đề.
- **Phối hợp:** hỏi người điều phối (M1) trước khi chạy để chắc chắn không ai chạy trùng instance đó.
- **Tiêu chí hoàn thành:** có file kết quả cho từng instance, báo cáo MLU mới so với MLU hiện có (nêu rõ có cải thiện hay không).

## Việc C3 — Không giao cho agent (do M1 làm)

Sửa nhãn trạng thái của các dòng waypoint ở Bảng 2 (`official_tables.jl`) và các thay đổi liên quan đến bảng chính thức do M1 làm để tránh xung đột.
