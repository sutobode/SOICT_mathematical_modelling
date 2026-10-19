# Trạng thái thực nghiệm

Cập nhật: **2026-10-20 03:00:04**

RAM trống: **6.9 GB**

## Tiến trình Julia

```
PID 7720 | start 10:38 | RAM 0.70 GB | CPU 67s
PID 24580 | start 21:44 | RAM 0.89 GB | CPU 18,254s
PID 30288 | start 01:06 | RAM 11.30 GB | CPU 6,798s
```

## Dòng cuối của log

- `log-P1.txt` (ghi 836 phút trước): == setA-20 P=1  1.79238985321e9
- `log-P2.txt` (ghi 827 phút trước): == setA-02 P=2  1.792390356649e9
- `log-overnight-m1-console.txt` (ghi 114 phút trước): [2026-10-20 01:06:01] lan thu 1: julia --project=orange orange/scripts/run_experiments.jl 2 3600 5 5 pc 1 5 -r1-5 12  (free RAM 15.9 GB)
- `log-pc-P1-04-r4-10.txt` (ghi 316 phút trước): == setA-04 P=1 pc=true  1.792421061439e9
- `log-pc-P1-05-r4-10.txt` (ghi 315 phút trước): == setA-05 P=1 pc=true  1.792421120879e9
- `log-pc-P1.txt` (ghi 774 phút trước): == setA-04 P=1 pc=true  1.792393555651e9
- `log-pc-P1b.txt` (ghi 656 phút trước): == setA-20 P=1 pc=true  1.792400636244e9
- `log-pc-P2-02-r4-10.txt` (ghi 316 phút trước): == setA-02 P=2 pc=true  1.792421061433e9
- `log-pc-P2-03-r4-10.txt` (ghi 251 phút trước): == setA-03 P=2 pc=true  1.792424947614e9
- `log-pc-P2-04-r2-10.txt` (ghi 305 phút trước): == setA-04 P=2 pc=true  1.792421718406e9
- `log-pc-P2-04-r7-10.txt` (ghi 245 phút trước): == setA-04 P=2 pc=true  1.79242532346e9
- `log-pc-P2-05-r1-5.txt` (ghi 114 phút trước): == setA-05 P=2 pc=true  1.792433163644e9
- `log-pc-P2.txt` (ghi 585 phút trước): == setA-04 P=2 pc=true  1.792404927433e9
- `log-pc-P2b.txt` (ghi 381 phút trước): == setA-04 P=2 pc=true  1.792417145496e9
- `log-verify-all.txt` (ghi 158 phút trước): checked 92 files; with problems or tolerance sensitivity: 0; max |MLU - CSV| = 0.00e+00
- `log-wp-P1.txt` (ghi 905 phút trước): == setA-13 P=1  free RAM 12.7 GiB
- `log-wp-P2.txt` (ghi 914 phút trước): == setA-06 P=2  free RAM 12.7 GiB
- `log-wp-cg-P1.txt` (ghi 734 phút trước): == setA-20 P=1 cg=true  free RAM 13.4 GiB
- `log-wp-cg-P2-17-18-20.txt` (ghi 321 phút trước): == setA-20 P=2 cg=true pc=false  free RAM 12.1 GiB
- `log-wp-cg-P2-19.txt` (ghi 332 phút trước): == setA-19 P=2 cg=true pc=false  free RAM 12.6 GiB
- `log-wp-cg-P2.txt` (ghi 332 phút trước): == setA-17 P=2 cg=true pc=false  free RAM 12.5 GiB
- `log-wp-cg-lns-P1.txt` (ghi 745 phút trước): == setA-14 P=1 cg=true pc=false  free RAM 13.3 GiB
- `log-wp-cg-lns-P2-13.txt` (ghi 469 phút trước): == setA-13 P=2 cg=true pc=false  free RAM 11.3 GiB
- `log-wp-cg-lns-P2.txt` (ghi 597 phút trước): == setA-10 P=2 cg=true pc=false  free RAM 14.8 GiB
- `log-wp-cg-pc-18-20.txt` (ghi 773 phút trước): == setA-20 P=2 cg=true pc=true  free RAM 13.9 GiB
- `log-wp-cg-pc-P1.txt` (ghi 777 phút trước): == setA-10 P=1 cg=true pc=true  free RAM 14.0 GiB
- `log-wp-fast-P2.txt` (ghi 291 phút trước): == setA-19 P=2 cg=true pc=false  free RAM 5.6 GiB

## Kết quả đã có (mỗi dòng một file CSV)

| Instance | t | Loại | Lần chạy | Trạng thái | MLU tốt nhất | Thời gian TB (s) | Gap lớn nhất | Cập nhật (phút trước) |
|---|---|---|---|---|---|---|---|---|
| setA-01 | 0 | theo cung | 10 | Optimal | 0.92938 | 0.4 | 4.92e-09 | 947 |
| setA-02 | 0 | theo cung | 10 | Optimal | 0.54858 | 1.2 | 1.83e-08 | 947 |
| setA-03 | 0 | theo cung | 10 | Optimal | 0.94354 | 3.2 | 3.91e-14 | 946 |
| setA-04 | 0 | theo cung | 3 | Not Optimal | 0.51026 | 1800.6 | 1.00e-01 | 853 |
| setA-05 | 0 | theo cung | 3 | Optimal | 0.11552 | 211.0 | 4.44e-08 | 836 |
| setA-06 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-07 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-08 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-09 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-10 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-11 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-12 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-13 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-14 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-15 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-16 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-17 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-18 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-19 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-20 | 0 | theo cung | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 836 |
| setA-01 | 0,1 | theo cung | 10 | Optimal | 0.92938 | 42.7 | 4.46e-09 | 827 |
| setA-02 | 0,1 | theo cung | 1 | Optimal | 0.90307 | 1898.5 | 0.00e+00 | 796 |
| setA-05 | 0,1 | theo cung [pc-r1-5] | 1 | Not Optimal | 0.99999 | 3617.8 | 1.00e+00 | 48 |
| setA-04 | 0,1 | theo cung [pc-r2-10] | 3 | Not Optimal | 0.58857 | 3609.0 | 1.00e+00 | 115 |
| setA-04 | 0 | theo cung [pc-r4-10] | 7 | Not Optimal | 0.50105 | 1801.0 | 1.00e+00 | 95 |
| setA-05 | 0 | theo cung [pc-r4-10] | 7 | Optimal | 0.11552 | 342.4 | 4.44e-08 | 251 |
| setA-02 | 0,1 | theo cung [pc-r4-10] | 6 | Optimal | 0.90307 | 3039.2 | 1.00e+00 | 10 |
| setA-03 | 0,1 | theo cung [pc-r4-10] | 7 | Optimal | 0.94354 | 1291.9 | 1.00e+00 | 98 |
| setA-01 | 0 | theo cung [pc] | 10 | Optimal | 0.92938 | 0.8 | 4.92e-09 | 777 |
| setA-02 | 0 | theo cung [pc] | 10 | Optimal | 0.54858 | 2.3 | 1.83e-08 | 776 |
| setA-03 | 0 | theo cung [pc] | 10 | Optimal | 0.94354 | 5.2 | 3.91e-14 | 774 |
| setA-04 | 0 | theo cung [pc] | 3 | Not Optimal | 0.51026 | 1800.7 | 1.00e-01 | 670 |
| setA-05 | 0 | theo cung [pc] | 3 | Optimal | 0.11552 | 172.7 | 4.44e-08 | 656 |
| setA-06 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-07 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-08 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-09 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-10 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-11 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-12 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-13 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-14 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-15 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-16 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-17 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-18 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-19 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-20 | 0 | theo cung [pc] | 1 | SKIPPED_TOO_LARGE | nan | nan | nan | 656 |
| setA-01 | 0,1 | theo cung [pc] | 10 | Optimal | 0.92938 | 39.3 | 4.46e-09 | 755 |
| setA-02 | 0,1 | theo cung [pc] | 3 | Optimal | 0.90307 | 2625.3 | 0.00e+00 | 623 |
| setA-03 | 0,1 | theo cung [pc] | 3 | Optimal | 0.94354 | 756.2 | 0.00e+00 | 585 |
| setA-04 | 0,1 | theo cung [pc] | 1 | Not Optimal | 0.58857 | 3614.6 | 1.00e+00 | 317 |
| setA-01 | 0 | waypoint | 1 | Optimal | 0.92938 | 0.0 | 0.00e+00 | 936 |
| setA-02 | 0 | waypoint | 1 | Optimal | 0.54858 | 0.0 | 0.00e+00 | 936 |
| setA-03 | 0 | waypoint | 1 | Optimal | 0.94354 | 0.0 | 0.00e+00 | 936 |
| setA-04 | 0 | waypoint | 1 | Optimal | 0.45912 | 1.0 | 0.00e+00 | 936 |
| setA-05 | 0 | waypoint | 1 | Optimal | 0.11552 | 0.3 | 0.00e+00 | 936 |
| setA-06 | 0 | waypoint | 1 | Optimal | 0.09859 | 10.7 | 9.08e-07 | 936 |
| setA-07 | 0 | waypoint | 1 | Optimal | 0.90799 | 2.7 | 0.00e+00 | 936 |
| setA-08 | 0 | waypoint | 1 | Optimal | 0.31890 | 1.2 | 0.00e+00 | 936 |
| setA-09 | 0 | waypoint | 1 | Optimal | 0.50538 | 2.0 | 0.00e+00 | 936 |
| setA-10 | 0 | waypoint | 1 | Not Optimal | 0.08261 | 1801.0 | 1.73e-01 | 906 |
| setA-11 | 0 | waypoint | 1 | Optimal | 0.61354 | 32.2 | 0.00e+00 | 905 |
| setA-12 | 0 | waypoint | 1 | Optimal | 0.64008 | 6.3 | 3.91e-10 | 905 |
| setA-01 | 0,1 | waypoint | 1 | Optimal | 0.92938 | 0.1 | 0.00e+00 | 916 |
| setA-02 | 0,1 | waypoint | 1 | Optimal | 0.90307 | 0.4 | 0.00e+00 | 916 |
| setA-03 | 0,1 | waypoint | 1 | Optimal | 0.94354 | 0.2 | 0.00e+00 | 916 |
| setA-04 | 0,1 | waypoint | 1 | Optimal | 0.58281 | 59.6 | 0.00e+00 | 915 |
| setA-05 | 0,1 | waypoint | 1 | Optimal | 0.20499 | 44.5 | 0.00e+00 | 914 |
| setA-16 | 0,1 | waypoint [cg-lns-fast] | 1 | Not Optimal | 0.51639 | 0.0 | nan | 291 |
| setA-19 | 0,1 | waypoint [cg-lns-fast] | 1 | Not Optimal | 0.10258 | 0.0 | nan | 175 |
| setA-10 | 0 | waypoint [cg-lns] | 1 | Not Optimal | 0.06957 | 300.1 | 3.71e-01 | 758 |
| setA-13 | 0 | waypoint [cg-lns] | 1 | Not Optimal | 0.03889 | 300.2 | 2.42e-01 | 745 |
| setA-14 | 0 | waypoint [cg-lns] | 1 | Optimal | 0.43421 | 0.6 | 0.00e+00 | 739 |
| setA-10 | 0,1 | waypoint [cg-lns] | 1 | Not Optimal | 0.10870 | 300.6 | 9.46e-01 | 560 |
| setA-13 | 0,1 | waypoint [cg-lns] | 1 | Not Optimal | 0.07692 | 302.0 | 9.88e-01 | 392 |
| setA-01 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.92938 | 0.0 | 0.00e+00 | 777 |
| setA-02 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.54858 | 0.0 | 0.00e+00 | 777 |
| setA-03 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.94354 | 0.0 | 0.00e+00 | 777 |
| setA-04 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.45912 | 0.8 | 1.11e-16 | 777 |
| setA-05 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.11552 | 0.0 | 0.00e+00 | 777 |
| setA-06 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.10141 | 3.4 | 8.66e-07 | 777 |
| setA-07 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.90799 | 0.3 | 0.00e+00 | 777 |
| setA-08 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.31890 | 0.1 | 0.00e+00 | 777 |
| setA-09 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.50538 | 0.1 | 0.00e+00 | 777 |
| setA-18 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.63337 | 0.8 | 0.00e+00 | 774 |
| setA-20 | 0 | waypoint [cg-pc] | 1 | Optimal | 0.99131 | 3.7 | 0.00e+00 | 774 |
| setA-18 | 0,1 | waypoint [cg-pc] | 1 | Optimal | 1.00000 | 18.4 | 0.00e+00 | 773 |
| setA-20 | 0,1 | waypoint [cg-pc] | 1 | Optimal | 0.99131 | 273.7 | 0.00e+00 | 762 |
| setA-01 | 0 | waypoint [cg] | 1 | Optimal | 0.92938 | 0.0 | 0.00e+00 | 885 |
| setA-02 | 0 | waypoint [cg] | 1 | Optimal | 0.54858 | 0.0 | 0.00e+00 | 885 |
| setA-03 | 0 | waypoint [cg] | 1 | Optimal | 0.94354 | 0.0 | 0.00e+00 | 885 |
| setA-04 | 0 | waypoint [cg] | 1 | Optimal | 0.45912 | 1.1 | 1.11e-16 | 885 |
| setA-05 | 0 | waypoint [cg] | 1 | Optimal | 0.11552 | 0.1 | 0.00e+00 | 885 |
| setA-06 | 0 | waypoint [cg] | 1 | Optimal | 0.10141 | 3.7 | 8.66e-07 | 885 |
| setA-07 | 0 | waypoint [cg] | 1 | Optimal | 0.90799 | 0.5 | 0.00e+00 | 884 |
| setA-08 | 0 | waypoint [cg] | 1 | Optimal | 0.31890 | 0.2 | 0.00e+00 | 884 |
| setA-09 | 0 | waypoint [cg] | 1 | Optimal | 0.50538 | 0.2 | 0.00e+00 | 884 |
| setA-10 | 0 | waypoint [cg] | 1 | Not Optimal | 0.07011 | 1800.2 | 2.55e-02 | 854 |
| setA-11 | 0 | waypoint [cg] | 1 | Optimal | 0.65142 | 0.5 | 1.36e-07 | 854 |
| setA-12 | 0 | waypoint [cg] | 1 | Optimal | 0.64008 | 0.1 | 0.00e+00 | 854 |
| setA-13 | 0 | waypoint [cg] | 1 | Not Optimal | 0.04487 | 1800.3 | 1.34e-01 | 821 |
| setA-14 | 0 | waypoint [cg] | 1 | Optimal | 0.43421 | 0.5 | 0.00e+00 | 821 |
| setA-15 | 0 | waypoint [cg] | 1 | Optimal | 0.82521 | 0.4 | 0.00e+00 | 821 |
| setA-16 | 0 | waypoint [cg] | 1 | Optimal | 0.12295 | 115.7 | 1.44e-06 | 814 |
| setA-17 | 0 | waypoint [cg] | 1 | Optimal | 0.42419 | 2.4 | 0.00e+00 | 814 |
| setA-18 | 0 | waypoint [cg] | 1 | Optimal | 0.63337 | 1.3 | 0.00e+00 | 814 |
| setA-19 | 0 | waypoint [cg] | 1 | Not Optimal | 0.06745 | 1800.2 | 2.78e-02 | 734 |
| setA-20 | 0 | waypoint [cg] | 1 | Optimal | 0.99131 | 4.9 | 0.00e+00 | 734 |
| setA-01 | 0,1 | waypoint [cg] | 1 | Optimal | 0.92938 | 0.1 | 0.00e+00 | 733 |
| setA-02 | 0,1 | waypoint [cg] | 1 | Optimal | 0.90307 | 0.1 | 0.00e+00 | 733 |
| setA-03 | 0,1 | waypoint [cg] | 1 | Optimal | 0.94354 | 0.1 | 0.00e+00 | 733 |
| setA-04 | 0,1 | waypoint [cg] | 1 | Optimal | 0.58281 | 17.4 | 0.00e+00 | 733 |
| setA-05 | 0,1 | waypoint [cg] | 1 | Optimal | 0.20499 | 1.9 | 0.00e+00 | 733 |
| setA-06 | 0,1 | waypoint [cg] | 1 | Optimal | 0.14085 | 2223.5 | 2.22e-16 | 695 |
| setA-07 | 0,1 | waypoint [cg] | 1 | Optimal | 0.90799 | 3.2 | 0.00e+00 | 695 |
| setA-08 | 0,1 | waypoint [cg] | 1 | Optimal | 0.31890 | 8.5 | 0.00e+00 | 695 |
| setA-09 | 0,1 | waypoint [cg] | 1 | Optimal | 0.84965 | 0.3 | 0.00e+00 | 695 |
| setA-10 | 0,1 | waypoint [cg] | 1 | Not Optimal | 1.00000 | 3600.3 | 9.32e-01 | 617 |
| setA-11 | 0,1 | waypoint [cg] | 1 | Optimal | 0.78579 | 1.3 | 0.00e+00 | 616 |
| setA-12 | 0,1 | waypoint [cg] | 1 | Optimal | 0.87987 | 1.3 | 0.00e+00 | 616 |
| setA-13 | 0,1 | waypoint [cg] | 1 | Not Optimal | 0.90171 | 3601.0 | 9.88e-01 | 513 |
| setA-14 | 0,1 | waypoint [cg] | 1 | Optimal | 0.53315 | 78.0 | 0.00e+00 | 512 |
| setA-15 | 0,1 | waypoint [cg] | 1 | Optimal | 0.89870 | 1.3 | 0.00e+00 | 511 |
| setA-16 | 0,1 | waypoint [cg] | 1 | Not Optimal | 0.94262 | 3605.1 | 8.61e-01 | 332 |
| setA-17 | 0,1 | waypoint [cg] | 1 | Optimal | 0.42419 | 527.3 | 0.00e+00 | 322 |
| setA-18 | 0,1 | waypoint [cg] | 1 | Optimal | 1.00000 | 17.2 | 0.00e+00 | 321 |
| setA-20 | 0,1 | waypoint [cg] | 1 | Optimal | 0.99131 | 597.5 | 0.00e+00 | 305 |

## Watchdog RAM (3 dòng cuối)

```
RAM ok, starting setA-04 P2 runs 2-10 at 21:55
RAM ok, starting setA-04 P2 runs 7-10 (second process) at 22:55
[2026-10-19T23:10:53] free 1.03 GB < 1.5 GB: stopping julia PID 24188 (5.80 GB)
```
