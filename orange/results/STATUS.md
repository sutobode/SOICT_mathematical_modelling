# Trạng thái thực nghiệm

Cập nhật: **2026-10-19 19:19:27**

RAM trống: **13.8 GB**

## Tiến trình Julia

```
PID 7720 | start 10:38 | RAM 0.42 GB | CPU 44s
PID 18892 | start 14:17 | RAM 0.49 GB | CPU 16,139s
PID 11856 | start 14:46 | RAM 0.96 GB | CPU 14,523s
PID 34516 | start 19:11 | RAM 0.75 GB | CPU 483s
```

## Dòng cuối của log

- `log-P1.txt` (ghi 375 phút trước): == setA-20 P=1  1.79238985321e9
- `log-P2.txt` (ghi 367 phút trước): == setA-02 P=2  1.792390356649e9
- `log-pc-P1.txt` (ghi 314 phút trước): == setA-04 P=1 pc=true  1.792393555651e9
- `log-pc-P1b.txt` (ghi 196 phút trước): == setA-20 P=1 pc=true  1.792400636244e9
- `log-pc-P2.txt` (ghi 124 phút trước): == setA-04 P=2 pc=true  1.792404927433e9
- `log-wp-P1.txt` (ghi 444 phút trước): == setA-13 P=1  free RAM 12.7 GiB
- `log-wp-P2.txt` (ghi 454 phút trước): == setA-06 P=2  free RAM 12.7 GiB
- `log-wp-cg-P1.txt` (ghi 273 phút trước): == setA-20 P=1 cg=true  free RAM 13.4 GiB
- `log-wp-cg-P2.txt` (ghi 51 phút trước): == setA-16 P=2 cg=true pc=false  free RAM 13.1 GiB
- `log-wp-cg-lns-P1.txt` (ghi 284 phút trước): == setA-14 P=1 cg=true pc=false  free RAM 13.3 GiB
- `log-wp-cg-lns-P2-13.txt` (ghi 8 phút trước): == setA-13 P=2 cg=true pc=false  free RAM 11.3 GiB
- `log-wp-cg-lns-P2.txt` (ghi 137 phút trước): == setA-10 P=2 cg=true pc=false  free RAM 14.8 GiB
- `log-wp-cg-pc-18-20.txt` (ghi 312 phút trước): == setA-20 P=2 cg=true pc=true  free RAM 13.9 GiB
- `log-wp-cg-pc-P1.txt` (ghi 316 phút trước): == setA-10 P=1 cg=true pc=true  free RAM 14.0 GiB

## Kết quả đã có (mỗi dòng một file CSV)

| Instance | t | Loại | Lần chạy | Trạng thái | MLU tốt nhất | Thời gian TB (s) | Gap lớn nhất | Cập nhật (phút trước) |
|---|---|---|---|---|---|---|---|---|
| setA-01 | 0 | theo cung | 10 | Optimal | 0.92938 | 0.4 | 4.92e-09 | 487 |
| setA-02 | 0 | theo cung | 10 | Optimal | 0.54858 | 1.2 | 1.83e-08 | 486 |
| setA-03 | 0 | theo cung | 10 | Optimal | 0.94354 | 3.2 | 3.91e-14 | 485 |
| setA-04 | 0 | theo cung | 3 | Not Optimal | 0.51026 | 1800.6 | 1.00e-01 | 392 |
| setA-05 | 0 | theo cung | 3 | Optimal | 0.11552 | 211.0 | 4.44e-08 | 375 |
| setA-06 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-07 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-08 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-09 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-10 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-11 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-12 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-13 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-14 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-15 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-16 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-17 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-18 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-19 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-20 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 375 |
| setA-01 | 0,1 | theo cung | 10 | Optimal | 0.92938 | 42.7 | 4.46e-09 | 367 |
| setA-02 | 0,1 | theo cung | 1 | Optimal | 0.90307 | 1898.5 | 0.00e+00 | 335 |
| setA-01 | 0 | theo cung [pc] | 10 | Optimal | 0.92938 | 0.8 | 4.92e-09 | 316 |
| setA-02 | 0 | theo cung [pc] | 10 | Optimal | 0.54858 | 2.3 | 1.83e-08 | 315 |
| setA-03 | 0 | theo cung [pc] | 10 | Optimal | 0.94354 | 5.2 | 3.91e-14 | 314 |
| setA-04 | 0 | theo cung [pc] | 3 | Not Optimal | 0.51026 | 1800.7 | 1.00e-01 | 209 |
| setA-05 | 0 | theo cung [pc] | 3 | Optimal | 0.11552 | 172.7 | 4.44e-08 | 196 |
| setA-06 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-07 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-08 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-09 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-10 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-11 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-12 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-13 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-14 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-15 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-16 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-17 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-18 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-19 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-20 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 196 |
| setA-01 | 0,1 | theo cung [pc] | 10 | Optimal | 0.92938 | 39.3 | 4.46e-09 | 294 |
| setA-02 | 0,1 | theo cung [pc] | 3 | Optimal | 0.90307 | 2625.3 | 0.00e+00 | 163 |
| setA-03 | 0,1 | theo cung [pc] | 3 | Optimal | 0.94354 | 756.2 | 0.00e+00 | 124 |
| setA-01 | 0 | waypoint | 1 | Optimal | 0.92938 | 0.0 | 0.00e+00 | 476 |
| setA-02 | 0 | waypoint | 1 | Optimal | 0.54858 | 0.0 | 0.00e+00 | 476 |
| setA-03 | 0 | waypoint | 1 | Optimal | 0.94354 | 0.0 | 0.00e+00 | 476 |
| setA-04 | 0 | waypoint | 1 | Optimal | 0.45912 | 1.0 | 0.00e+00 | 476 |
| setA-05 | 0 | waypoint | 1 | Optimal | 0.11552 | 0.3 | 0.00e+00 | 476 |
| setA-06 | 0 | waypoint | 1 | Optimal | 0.09859 | 10.7 | 9.08e-07 | 476 |
| setA-07 | 0 | waypoint | 1 | Optimal | 0.90799 | 2.7 | 0.00e+00 | 475 |
| setA-08 | 0 | waypoint | 1 | Optimal | 0.31890 | 1.2 | 0.00e+00 | 475 |
| setA-09 | 0 | waypoint | 1 | Optimal | 0.50538 | 2.0 | 0.00e+00 | 475 |
| setA-10 | 0 | waypoint | 1 | Not Optimal | 0.08261 | 1801.0 | 1.73e-01 | 445 |
| setA-11 | 0 | waypoint | 1 | Optimal | 0.61354 | 32.2 | 0.00e+00 | 444 |
| setA-12 | 0 | waypoint | 1 | Optimal | 0.64008 | 6.3 | 3.91e-10 | 444 |
| setA-01 | 0,1 | waypoint | 1 | Optimal | 0.92938 | 0.1 | 0.00e+00 | 456 |
| setA-02 | 0,1 | waypoint | 1 | Optimal | 0.90307 | 0.4 | 0.00e+00 | 456 |
| setA-03 | 0,1 | waypoint | 1 | Optimal | 0.94354 | 0.2 | 0.00e+00 | 456 |
| setA-04 | 0,1 | waypoint | 1 | Optimal | 0.58281 | 59.6 | 0.00e+00 | 455 |
| setA-05 | 0,1 | waypoint | 1 | Optimal | 0.20499 | 44.5 | 0.00e+00 | 454 |
| setA-10 | 0 | waypoint [cg-lns] | 1 | Not Optimal | 0.06957 | 300.1 | 3.71e-01 | 297 |
| setA-13 | 0 | waypoint [cg-lns] | 1 | Not Optimal | 0.03889 | 300.2 | 2.42e-01 | 284 |
| setA-14 | 0 | waypoint [cg-lns] | 1 | Optimal | 0.43421 | 0.6 | 0.00e+00 | 279 |
| setA-10 | 0,1 | waypoint [cg-lns] | 1 | Not Optimal | 0.10870 | 300.6 | 9.46e-01 | 99 |
| setA-01 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.92938 | 0.0 | 0.00e+00 | 316 |
| setA-02 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.54858 | 0.0 | 0.00e+00 | 316 |
| setA-03 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.94354 | 0.0 | 0.00e+00 | 316 |
| setA-04 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.45912 | 0.8 | 1.11e-16 | 316 |
| setA-05 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.11552 | 0.0 | 0.00e+00 | 316 |
| setA-06 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.10141 | 3.4 | 8.66e-07 | 316 |
| setA-07 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.90799 | 0.3 | 0.00e+00 | 316 |
| setA-08 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.31890 | 0.1 | 0.00e+00 | 316 |
| setA-09 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.50538 | 0.1 | 0.00e+00 | 316 |
| setA-18 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.63337 | 0.8 | 0.00e+00 | 314 |
| setA-20 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.99131 | 3.7 | 0.00e+00 | 313 |
| setA-18 | 0,1 | waypoint [cg-pc] | 1 | Optimal | 1.00000 | 18.4 | 0.00e+00 | 312 |
| setA-20 | 0,1 | waypoint [cg-pc] | 1 | Optimal | 0.99131 | 273.7 | 0.00e+00 | 302 |
| setA-01 | 0 | waypoint [cg] | 1 | Optimal | 0.92938 | 0.0 | 0.00e+00 | 424 |
| setA-02 | 0 | waypoint [cg] | 1 | Optimal | 0.54858 | 0.0 | 0.00e+00 | 424 |
| setA-03 | 0 | waypoint [cg] | 1 | Optimal | 0.94354 | 0.0 | 0.00e+00 | 424 |
| setA-04 | 0 | waypoint [cg] | 1 | Optimal | 0.45912 | 1.1 | 1.11e-16 | 424 |
| setA-05 | 0 | waypoint [cg] | 1 | Optimal | 0.11552 | 0.1 | 0.00e+00 | 424 |
| setA-06 | 0 | waypoint [cg] | 1 | Optimal | 0.10141 | 3.7 | 8.66e-07 | 424 |
| setA-07 | 0 | waypoint [cg] | 1 | Optimal | 0.90799 | 0.5 | 0.00e+00 | 424 |
| setA-08 | 0 | waypoint [cg] | 1 | Optimal | 0.31890 | 0.2 | 0.00e+00 | 424 |
| setA-09 | 0 | waypoint [cg] | 1 | Optimal | 0.50538 | 0.2 | 0.00e+00 | 424 |
| setA-10 | 0 | waypoint [cg] | 1 | Not Optimal | 0.07011 | 1800.2 | 2.55e-02 | 393 |
| setA-11 | 0 | waypoint [cg] | 1 | Optimal | 0.65142 | 0.5 | 1.36e-07 | 393 |
| setA-12 | 0 | waypoint [cg] | 1 | Optimal | 0.64008 | 0.1 | 0.00e+00 | 393 |
| setA-13 | 0 | waypoint [cg] | 1 | Not Optimal | 0.04487 | 1800.3 | 1.34e-01 | 361 |
| setA-14 | 0 | waypoint [cg] | 1 | Optimal | 0.43421 | 0.5 | 0.00e+00 | 360 |
| setA-15 | 0 | waypoint [cg] | 1 | Optimal | 0.82521 | 0.4 | 0.00e+00 | 360 |
| setA-16 | 0 | waypoint [cg] | 1 | Optimal | 0.12295 | 115.7 | 1.44e-06 | 354 |
| setA-17 | 0 | waypoint [cg] | 1 | Optimal | 0.42419 | 2.4 | 0.00e+00 | 353 |
| setA-18 | 0 | waypoint [cg] | 1 | Optimal | 0.63337 | 1.3 | 0.00e+00 | 353 |
| setA-19 | 0 | waypoint [cg] | 1 | Not Optimal | 0.06745 | 1800.2 | 2.78e-02 | 273 |
| setA-20 | 0 | waypoint [cg] | 1 | Optimal | 0.99131 | 4.9 | 0.00e+00 | 273 |
| setA-01 | 0,1 | waypoint [cg] | 1 | Optimal | 0.92938 | 0.1 | 0.00e+00 | 273 |
| setA-02 | 0,1 | waypoint [cg] | 1 | Optimal | 0.90307 | 0.1 | 0.00e+00 | 273 |
| setA-03 | 0,1 | waypoint [cg] | 1 | Optimal | 0.94354 | 0.1 | 0.00e+00 | 273 |
| setA-04 | 0,1 | waypoint [cg] | 1 | Optimal | 0.58281 | 17.4 | 0.00e+00 | 272 |
| setA-05 | 0,1 | waypoint [cg] | 1 | Optimal | 0.20499 | 1.9 | 0.00e+00 | 272 |
| setA-06 | 0,1 | waypoint [cg] | 1 | Optimal | 0.14085 | 2223.5 | 2.22e-16 | 234 |
| setA-07 | 0,1 | waypoint [cg] | 1 | Optimal | 0.90799 | 3.2 | 0.00e+00 | 234 |
| setA-08 | 0,1 | waypoint [cg] | 1 | Optimal | 0.31890 | 8.5 | 0.00e+00 | 234 |
| setA-09 | 0,1 | waypoint [cg] | 1 | Optimal | 0.84965 | 0.3 | 0.00e+00 | 234 |
| setA-10 | 0,1 | waypoint [cg] | 1 | Not Optimal | 1.00000 | 3600.3 | 9.32e-01 | 156 |
| setA-11 | 0,1 | waypoint [cg] | 1 | Optimal | 0.78579 | 1.3 | 0.00e+00 | 156 |
| setA-12 | 0,1 | waypoint [cg] | 1 | Optimal | 0.87987 | 1.3 | 0.00e+00 | 156 |
| setA-13 | 0,1 | waypoint [cg] | 1 | Not Optimal | 0.90171 | 3601.0 | 9.88e-01 | 52 |
| setA-14 | 0,1 | waypoint [cg] | 1 | Optimal | 0.53315 | 78.0 | 0.00e+00 | 51 |
| setA-15 | 0,1 | waypoint [cg] | 1 | Optimal | 0.89870 | 1.3 | 0.00e+00 | 51 |

## Watchdog RAM (3 dòng cuối)

```
[2026-10-19T12:07:13] watchdog started (min free 1.5 GB, interval 15s)
[2026-10-19T12:07:26] watchdog started (min free 1.5 GB, interval 15s)
```
