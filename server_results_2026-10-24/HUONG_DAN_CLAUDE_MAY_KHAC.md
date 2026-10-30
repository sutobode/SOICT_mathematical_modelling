# Dùng Claude trên máy khác để kiểm tra tiến độ thí nghiệm

Tài liệu này giúp bạn (và Claude Code trên một máy mới) kiểm tra đợt chạy chính thức trên server `10.0.12.30` mà không làm hỏng gì.
Checklist chi tiết nằm cùng thư mục: `/home/darkweb/network-model-test/CHECKLIST_SANG_MAI.md`.

---

## 1. Chuẩn bị trên máy mới (khoảng 5 phút)

### 1.1. Cài Claude Code
Dùng một trong các cách sau:
- **VS Code:** cài extension "Claude Code" rồi đăng nhập.
- **Terminal:** cài Claude Code CLI theo hướng dẫn chính thức tại https://docs.claude.com (mục Claude Code), sau đó chạy `claude` và đăng nhập.

Mở Claude Code trong một thư mục **trống** (ví dụ `~/check-server`). Không cần clone repo.

### 1.2. Đặt biến môi trường chứa thông tin server
Định dạng giống máy cũ: `ip/username/password`, tức `10.0.12.30/darkweb/<mật khẩu>`.
**Không** ghi mật khẩu vào file hay vào khung chat với Claude.

- **Windows (PowerShell), đặt cho tài khoản rồi mở lại VS Code/terminal:**
  ```powershell
  [Environment]::SetEnvironmentVariable('MY_SERVER_INFOR', '10.0.12.30/darkweb/<mật khẩu>', 'User')
  ```
- **Linux/macOS (chỉ phiên hiện tại):**
  ```bash
  read -s -p "Password: " PW; export MY_SERVER_INFOR="10.0.12.30/darkweb/$PW"; unset PW
  claude          # chạy Claude từ chính terminal này để nó thấy biến
  ```

### 1.3. Kiểm tra máy mới vào được server
- Phải ở trong cùng mạng hoặc VPN mà máy cũ đang dùng, vì `10.0.12.30` là IP nội bộ.
- Thử bằng tay: `ssh darkweb@10.0.12.30` rồi nhập mật khẩu. Vào được là ổn.

---

## 2. Prompt dán vào Claude

Copy nguyên khối dưới đây vào Claude Code:

````text
Tôi cần bạn KIỂM TRA (chỉ đọc) tiến độ một đợt chạy thí nghiệm trên server Linux qua SSH.

Kết nối:
- Thông tin server nằm trong biến môi trường MY_SERVER_INFOR, định dạng ip/username/password.
  Không in mật khẩu ra màn hình, không ghi nó vào file, không gửi nó đi đâu khác.
- Nếu có `sshpass` thì dùng: sshpass -e ssh (đặt SSHPASS từ phần password của biến).
- Nếu là Windows không có sshpass: tạo file askpass.cmd trong thư mục tạm với nội dung
    @powershell -NoProfile -Command "[Console]::Out.Write(($env:MY_SERVER_INFOR -split '/')[2])"
  rồi đặt SSH_ASKPASS=<đường dẫn askpass.cmd>, SSH_ASKPASS_REQUIRE=force, DISPLAY=dummy:0 và gọi ssh bình thường.
  Lưu ý: PowerShell 5.1 làm mất dấu nháy kép trong tham số gửi cho ssh. Lệnh phức tạp thì
  ghi vào file .sh, scp lên server rồi chạy `bash file.sh`, hoặc dùng Git Bash.

Phạm vi và quy tắc (BẮT BUỘC):
- Chỉ thao tác trong /home/darkweb/network-model-test. Server dùng chung: KHÔNG kill, KHÔNG renice,
  KHÔNG đụng tiến trình nào ngoài đợt chạy này (ví dụ các job trong /home/darkweb/duc/...).
- Mặc định CHỈ ĐỌC. Không sửa code, test, file kết quả, best_known.csv, bảng, artifact.
- Không dùng ORANGE_FORCE_RESTART. Không chạy thêm job Julia. Không chạy lại pipeline.sh (bản cũ).
- Chỉ khi tôi đồng ý rõ ràng mới được khởi chạy lại pipeline2.sh (xem mục "Nếu tiến trình đã chết"
  trong CHECKLIST_SANG_MAI.md).

Việc cần làm:
1. SSH vào server, đọc /home/darkweb/network-model-test/CHECKLIST_SANG_MAI.md và làm theo các bước 1–5 của nó.
2. Chạy `bash /home/darkweb/network-model-test/status.sh 30`.
3. Báo cáo bằng tiếng Việt, ngắn gọn:
   - Tiến trình còn chạy không (pipeline2.sh / tiến trình chờ / julia), batch nào đang chạy, instance và run nào.
   - Các batch đã xong (logs/v2_*.done) và thời điểm START/END trong logs/pipeline.log.
   - Số run ran/skipped/incomplete cho từng instance trong mỗi logs/v2_*.log.
   - Có STOP, NOT STARTED, attempt>1, incomplete, SKIPPED_LOW_MEMORY, ERROR, OutOfMemory không.
   - RAM trống (free -h), swap, ổ đĩa.
   - Ước lượng thời điểm xong (giờ UTC và giờ VN = UTC+7) so với hạn chót 00:00 UTC 23/10.
   - Kết luận: BÌNH THƯỜNG / CẦN CHÚ Ý / CÓ LỖI, kèm việc tôi nên làm.
````

---

## 3. Bối cảnh để bạn đọc kết quả Claude báo về

| Mục | Giá trị |
|---|---|
| Thư mục gốc | `/home/darkweb/network-model-test` |
| Repo | `SOICT_mathematical_modelling/` (nhánh `hung`, commit `0da1a520dc086e2a7c3f2f74a6212205376680be`) |
| Script điều phối đang dùng | `pipeline2.sh` (có hạn chót) |
| Xem nhanh | `bash status.sh` |
| Log | `logs/pipeline.log` (dòng thời gian), `logs/v2_<batch>.log` (từng batch) |
| Kết quả | `SOICT_mathematical_modelling/orange/results/` |
| Bảng (tạo ở cuối) | `orange/results/table_official_P1.md` và `P2.md`, `report/table_official_P*.tex` |
| Hạn chót chạy thí nghiệm | 00:00 UTC 23/10 = 07:00 VN; bảng xong trước 8h VN |
| Ngưỡng RAM | Dừng nếu RAM trống dưới 40 GB, kiểm tra trước mỗi batch |

Thứ tự batch trong `pipeline2.sh`, chạy **tuần tự**, mỗi lúc 1 job Julia 1 luồng:

| Batch | Nội dung | Dự kiến xong (giờ VN) |
|---|---|---|
| `p1_s01-03` | P=1 setA-01..03 | Đã xong 20/10 (30/30 run hợp lệ) |
| `p2_s01-03` | P=2 setA-01..03 | khoảng 11h–14h ngày 21/10 |
| `p1_s04-05` | P=1 setA-04..05 | khoảng 17h–20h ngày 21/10 |
| `p2_s04-05` | P=2 setA-04..05 | khoảng 16h–19h ngày 22/10 |
| `wp_p1_s10` → `wp_p2_s07` | Tùy chọn, model restricted waypoint | tối 22/10 nếu còn thời gian |

**Sáng 21/10, tình trạng bình thường sẽ là:**
- Batch `p2_s01-03` đang chạy, nhiều khả năng ở setA-02 P=2 (khoảng 50–60 phút mỗi run).
- Có dòng `bash -c while kill -0 1125961 ... pipeline2.sh`. Đây là tiến trình chờ batch hiện tại xong để khởi chạy lại pipeline với ngưỡng RAM 40 GB, **không phải lỗi**.
- Không có `incomplete` hay `STOP`.

**Các dấu hiệu cần xử lý:**
- Không có tiến trình nào và log chưa có `V2 PIPELINE FINISHED`: tiến trình đã chết. Làm theo Bước 6 trong checklist.
- Có `STOP: MemAvailable=...`: RAM thiếu. Chờ RAM trống lại rồi khởi chạy lại `pipeline2.sh`.
- Có `incomplete`, `ERROR` hoặc `SKIPPED_LOW_MEMORY`: ghi lại instance, P và run, đừng vá tay.

**Câu hỏi còn treo:** chạy song song 5 worker (mỗi worker 1 luồng) để xong sớm hơn khoảng 1 ngày. Lúc viết tài liệu này, việc đó **chưa được duyệt**, nên đợt chạy vẫn tuần tự. Nếu muốn làm, hãy yêu cầu Claude rõ ràng, kèm đề xuất:
- Giữ nguyên batch đang chạy.
- Thêm các worker: P=1 setA-04..05; P=2 setA-04; P=2 setA-05; WP P=1 setA-10 rồi WP P=2 setA-07.
- Khi đó phải dừng tiến trình chờ hoặc sửa `pipeline2.sh`, để nó không chạy lại các batch trùng lặp.

---

## 4. Muốn tự kiểm tra không cần Claude

```bash
ssh darkweb@10.0.12.30
bash /home/darkweb/network-model-test/status.sh 30
less /home/darkweb/network-model-test/CHECKLIST_SANG_MAI.md
```

## 5. Tải tài liệu này về máy

```bash
scp darkweb@10.0.12.30:/home/darkweb/network-model-test/HUONG_DAN_CLAUDE_MAY_KHAC.md .
scp darkweb@10.0.12.30:/home/darkweb/network-model-test/CHECKLIST_SANG_MAI.md .
```
