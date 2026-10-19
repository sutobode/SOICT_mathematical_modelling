# Trạng thái thực nghiệm

Cập nhật: **2026-10-19 21:43:16**

RAM trống: **10.8 GB**

## Tiến trình Julia

```
PID 7720 | start 10:38 | RAM 0.27 GB | CPU 51s
PID 30732 | start 20:39 | RAM 1.55 GB | CPU 3,763s
PID 33104 | start 21:28 | RAM 1.00 GB | CPU 889s
PID 26672 | start 21:33 | RAM 1.02 GB | CPU 579s
PID 28028 | start 21:38 | RAM 1.03 GB | CPU 256s
PID 22284 | start 21:41 | RAM 0.55 GB | CPU 72s
```

## Dòng cuối của log

- `log-P1.txt` (ghi 519 phút trước): == setA-20 P=1  1.79238985321e9
- `log-P2.txt` (ghi 511 phút trước): == setA-02 P=2  1.792390356649e9
- `log-pc-P1.txt` (ghi 457 phút trước): == setA-04 P=1 pc=true  1.792393555651e9
- `log-pc-P1b.txt` (ghi 339 phút trước): == setA-20 P=1 pc=true  1.792400636244e9
- `log-pc-P2.txt` (ghi 268 phút trước): == setA-04 P=2 pc=true  1.792404927433e9
- `log-pc-P2b.txt` (ghi 64 phút trước): == setA-04 P=2 pc=true  1.792417145496e9
- `log-wp-P1.txt` (ghi 588 phút trước): == setA-13 P=1  free RAM 12.7 GiB
- `log-wp-P2.txt` (ghi 598 phút trước): == setA-06 P=2  free RAM 12.7 GiB
- `log-wp-cg-P1.txt` (ghi 417 phút trước): == setA-20 P=1 cg=true  free RAM 13.4 GiB
- `log-wp-cg-P2-17-18-20.txt` (ghi 4 phút trước): == setA-20 P=2 cg=true pc=false  free RAM 12.1 GiB
- `log-wp-cg-P2-19.txt` (ghi 15 phút trước): == setA-19 P=2 cg=true pc=false  free RAM 12.6 GiB
- `log-wp-cg-P2.txt` (ghi 15 phút trước): == setA-17 P=2 cg=true pc=false  free RAM 12.5 GiB
- `log-wp-cg-lns-P1.txt` (ghi 428 phút trước): == setA-14 P=1 cg=true pc=false  free RAM 13.3 GiB
- `log-wp-cg-lns-P2-13.txt` (ghi 152 phút trước): == setA-13 P=2 cg=true pc=false  free RAM 11.3 GiB
- `log-wp-cg-lns-P2.txt` (ghi 280 phút trước): == setA-10 P=2 cg=true pc=false  free RAM 14.8 GiB
- `log-wp-cg-pc-18-20.txt` (ghi 456 phút trước): == setA-20 P=2 cg=true pc=true  free RAM 13.9 GiB
- `log-wp-cg-pc-P1.txt` (ghi 460 phút trước): == setA-10 P=1 cg=true pc=true  free RAM 14.0 GiB
- `log-wp-fast-P2.txt` (ghi 10 phút trước): == setA-16 P=2 cg=true pc=false  free RAM 10.8 GiB

## Kết quả đã có (mỗi dòng một file CSV)

| Instance | t | Loại | Lần chạy | Trạng thái | MLU tốt nhất | Thời gian TB (s) | Gap lớn nhất | Cập nhật (phút trước) |
|---|---|---|---|---|---|---|---|---|
| setA-01 | 0 | theo cung | 10 | Optimal | 0.92938 | 0.4 | 4.92e-09 | 630 |
| setA-02 | 0 | theo cung | 10 | Optimal | 0.54858 | 1.2 | 1.83e-08 | 630 |
| setA-03 | 0 | theo cung | 10 | Optimal | 0.94354 | 3.2 | 3.91e-14 | 629 |
| setA-04 | 0 | theo cung | 3 | Not Optimal | 0.51026 | 1800.6 | 1.00e-01 | 536 |
| setA-05 | 0 | theo cung | 3 | Optimal | 0.11552 | 211.0 | 4.44e-08 | 519 |
| setA-06 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-07 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-08 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-09 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-10 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-11 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-12 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-13 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-14 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-15 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-16 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-17 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-18 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-19 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-20 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 519 |
| setA-01 | 0,1 | theo cung | 10 | Optimal | 0.92938 | 42.7 | 4.46e-09 | 511 |
| setA-02 | 0,1 | theo cung | 1 | Optimal | 0.90307 | 1898.5 | 0.00e+00 | 479 |
| setA-01 | 0 | theo cung [pc] | 10 | Optimal | 0.92938 | 0.8 | 4.92e-09 | 460 |
| setA-02 | 0 | theo cung [pc] | 10 | Optimal | 0.54858 | 2.3 | 1.83e-08 | 459 |
| setA-03 | 0 | theo cung [pc] | 10 | Optimal | 0.94354 | 5.2 | 3.91e-14 | 457 |
| setA-04 | 0 | theo cung [pc] | 3 | Not Optimal | 0.51026 | 1800.7 | 1.00e-01 | 353 |
| setA-05 | 0 | theo cung [pc] | 3 | Optimal | 0.11552 | 172.7 | 4.44e-08 | 339 |
| setA-06 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-07 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-08 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-09 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-10 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-11 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-12 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-13 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-14 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-15 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-16 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-17 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-18 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-19 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-20 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 339 |
| setA-01 | 0,1 | theo cung [pc] | 10 | Optimal | 0.92938 | 39.3 | 4.46e-09 | 438 |
| setA-02 | 0,1 | theo cung [pc] | 3 | Optimal | 0.90307 | 2625.3 | 0.00e+00 | 306 |
| setA-03 | 0,1 | theo cung [pc] | 3 | Optimal | 0.94354 | 756.2 | 0.00e+00 | 268 |
| setA-04 | 0,1 | theo cung [pc] | 1 | Not Optimal | 0.58857 | 3614.6 | 1.00e+00 | 1 |
| setA-01 | 0 | waypoint | 1 | Optimal | 0.92938 | 0.0 | 0.00e+00 | 620 |
| setA-02 | 0 | waypoint | 1 | Optimal | 0.54858 | 0.0 | 0.00e+00 | 620 |
| setA-03 | 0 | waypoint | 1 | Optimal | 0.94354 | 0.0 | 0.00e+00 | 620 |
| setA-04 | 0 | waypoint | 1 | Optimal | 0.45912 | 1.0 | 0.00e+00 | 620 |
| setA-05 | 0 | waypoint | 1 | Optimal | 0.11552 | 0.3 | 0.00e+00 | 620 |
| setA-06 | 0 | waypoint | 1 | Optimal | 0.09859 | 10.7 | 9.08e-07 | 619 |
| setA-07 | 0 | waypoint | 1 | Optimal | 0.90799 | 2.7 | 0.00e+00 | 619 |
| setA-08 | 0 | waypoint | 1 | Optimal | 0.31890 | 1.2 | 0.00e+00 | 619 |
| setA-09 | 0 | waypoint | 1 | Optimal | 0.50538 | 2.0 | 0.00e+00 | 619 |
| setA-10 | 0 | waypoint | 1 | Not Optimal | 0.08261 | 1801.0 | 1.73e-01 | 589 |
| setA-11 | 0 | waypoint | 1 | Optimal | 0.61354 | 32.2 | 0.00e+00 | 588 |
| setA-12 | 0 | waypoint | 1 | Optimal | 0.64008 | 6.3 | 3.91e-10 | 588 |
| setA-01 | 0,1 | waypoint | 1 | Optimal | 0.92938 | 0.1 | 0.00e+00 | 599 |
| setA-02 | 0,1 | waypoint | 1 | Optimal | 0.90307 | 0.4 | 0.00e+00 | 599 |
| setA-03 | 0,1 | waypoint | 1 | Optimal | 0.94354 | 0.2 | 0.00e+00 | 599 |
| setA-04 | 0,1 | waypoint | 1 | Optimal | 0.58281 | 59.6 | 0.00e+00 | 598 |
| setA-05 | 0,1 | waypoint | 1 | Optimal | 0.20499 | 44.5 | 0.00e+00 | 598 |
| setA-10 | 0 | waypoint [cg-lns] | 1 | Not Optimal | 0.06957 | 300.1 | 3.71e-01 | 441 |
| setA-13 | 0 | waypoint [cg-lns] | 1 | Not Optimal | 0.03889 | 300.2 | 2.42e-01 | 428 |
| setA-14 | 0 | waypoint [cg-lns] | 1 | Optimal | 0.43421 | 0.6 | 0.00e+00 | 423 |
| setA-10 | 0,1 | waypoint [cg-lns] | 1 | Not Optimal | 0.10870 | 300.6 | 9.46e-01 | 243 |
| setA-13 | 0,1 | waypoint [cg-lns] | 1 | Not Optimal | 0.07692 | 302.0 | 9.88e-01 | 75 |
| setA-01 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.92938 | 0.0 | 0.00e+00 | 460 |
| setA-02 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.54858 | 0.0 | 0.00e+00 | 460 |
| setA-03 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.94354 | 0.0 | 0.00e+00 | 460 |
| setA-04 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.45912 | 0.8 | 1.11e-16 | 460 |
| setA-05 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.11552 | 0.0 | 0.00e+00 | 460 |
| setA-06 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.10141 | 3.4 | 8.66e-07 | 460 |
| setA-07 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.90799 | 0.3 | 0.00e+00 | 460 |
| setA-08 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.31890 | 0.1 | 0.00e+00 | 460 |
| setA-09 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.50538 | 0.1 | 0.00e+00 | 460 |
| setA-18 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.63337 | 0.8 | 0.00e+00 | 458 |
| setA-20 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.99131 | 3.7 | 0.00e+00 | 457 |
| setA-18 | 0,1 | waypoint [cg-pc] | 1 | Optimal | 1.00000 | 18.4 | 0.00e+00 | 456 |
| setA-20 | 0,1 | waypoint [cg-pc] | 1 | Optimal | 0.99131 | 273.7 | 0.00e+00 | 446 |
| setA-01 | 0 | waypoint [cg] | 1 | Optimal | 0.92938 | 0.0 | 0.00e+00 | 568 |
| setA-02 | 0 | waypoint [cg] | 1 | Optimal | 0.54858 | 0.0 | 0.00e+00 | 568 |
| setA-03 | 0 | waypoint [cg] | 1 | Optimal | 0.94354 | 0.0 | 0.00e+00 | 568 |
| setA-04 | 0 | waypoint [cg] | 1 | Optimal | 0.45912 | 1.1 | 1.11e-16 | 568 |
| setA-05 | 0 | waypoint [cg] | 1 | Optimal | 0.11552 | 0.1 | 0.00e+00 | 568 |
| setA-06 | 0 | waypoint [cg] | 1 | Optimal | 0.10141 | 3.7 | 8.66e-07 | 568 |
| setA-07 | 0 | waypoint [cg] | 1 | Optimal | 0.90799 | 0.5 | 0.00e+00 | 568 |
| setA-08 | 0 | waypoint [cg] | 1 | Optimal | 0.31890 | 0.2 | 0.00e+00 | 568 |
| setA-09 | 0 | waypoint [cg] | 1 | Optimal | 0.50538 | 0.2 | 0.00e+00 | 568 |
| setA-10 | 0 | waypoint [cg] | 1 | Not Optimal | 0.07011 | 1800.2 | 2.55e-02 | 537 |
| setA-11 | 0 | waypoint [cg] | 1 | Optimal | 0.65142 | 0.5 | 1.36e-07 | 537 |
| setA-12 | 0 | waypoint [cg] | 1 | Optimal | 0.64008 | 0.1 | 0.00e+00 | 537 |
| setA-13 | 0 | waypoint [cg] | 1 | Not Optimal | 0.04487 | 1800.3 | 1.34e-01 | 504 |
| setA-14 | 0 | waypoint [cg] | 1 | Optimal | 0.43421 | 0.5 | 0.00e+00 | 504 |
| setA-15 | 0 | waypoint [cg] | 1 | Optimal | 0.82521 | 0.4 | 0.00e+00 | 504 |
| setA-16 | 0 | waypoint [cg] | 1 | Optimal | 0.12295 | 115.7 | 1.44e-06 | 497 |
| setA-17 | 0 | waypoint [cg] | 1 | Optimal | 0.42419 | 2.4 | 0.00e+00 | 497 |
| setA-18 | 0 | waypoint [cg] | 1 | Optimal | 0.63337 | 1.3 | 0.00e+00 | 497 |
| setA-19 | 0 | waypoint [cg] | 1 | Not Optimal | 0.06745 | 1800.2 | 2.78e-02 | 417 |
| setA-20 | 0 | waypoint [cg] | 1 | Optimal | 0.99131 | 4.9 | 0.00e+00 | 417 |
| setA-01 | 0,1 | waypoint [cg] | 1 | Optimal | 0.92938 | 0.1 | 0.00e+00 | 416 |
| setA-02 | 0,1 | waypoint [cg] | 1 | Optimal | 0.90307 | 0.1 | 0.00e+00 | 416 |
| setA-03 | 0,1 | waypoint [cg] | 1 | Optimal | 0.94354 | 0.1 | 0.00e+00 | 416 |
| setA-04 | 0,1 | waypoint [cg] | 1 | Optimal | 0.58281 | 17.4 | 0.00e+00 | 416 |
| setA-05 | 0,1 | waypoint [cg] | 1 | Optimal | 0.20499 | 1.9 | 0.00e+00 | 416 |
| setA-06 | 0,1 | waypoint [cg] | 1 | Optimal | 0.14085 | 2223.5 | 2.22e-16 | 378 |
| setA-07 | 0,1 | waypoint [cg] | 1 | Optimal | 0.90799 | 3.2 | 0.00e+00 | 378 |
| setA-08 | 0,1 | waypoint [cg] | 1 | Optimal | 0.31890 | 8.5 | 0.00e+00 | 378 |
| setA-09 | 0,1 | waypoint [cg] | 1 | Optimal | 0.84965 | 0.3 | 0.00e+00 | 378 |
| setA-10 | 0,1 | waypoint [cg] | 1 | Not Optimal | 1.00000 | 3600.3 | 9.32e-01 | 300 |
| setA-11 | 0,1 | waypoint [cg] | 1 | Optimal | 0.78579 | 1.3 | 0.00e+00 | 300 |
| setA-12 | 0,1 | waypoint [cg] | 1 | Optimal | 0.87987 | 1.3 | 0.00e+00 | 300 |
| setA-13 | 0,1 | waypoint [cg] | 1 | Not Optimal | 0.90171 | 3601.0 | 9.88e-01 | 196 |
| setA-14 | 0,1 | waypoint [cg] | 1 | Optimal | 0.53315 | 78.0 | 0.00e+00 | 195 |
| setA-15 | 0,1 | waypoint [cg] | 1 | Optimal | 0.89870 | 1.3 | 0.00e+00 | 195 |
| setA-16 | 0,1 | waypoint [cg] | 1 | Not Optimal | 0.94262 | 3605.1 | 8.61e-01 | 15 |
| setA-17 | 0,1 | waypoint [cg] | 1 | Optimal | 0.42419 | 527.3 | 0.00e+00 | 5 |
| setA-18 | 0,1 | waypoint [cg] | 1 | Optimal | 1.00000 | 17.2 | 0.00e+00 | 4 |

## Watchdog RAM (3 dòng cuối)

```
[2026-10-19T12:07:13] watchdog started (min free 1.5 GB, interval 15s)
[2026-10-19T12:07:26] watchdog started (min free 1.5 GB, interval 15s)
chain 11856 stopped after setA-16 finished at 21:28
```
