# Table 1 -- time period 0 only, limit 1800 s (step 6)

| Instance | Vertices | Links | Demands | Best objective (MLU) | CPU time (s) | Status | Gap | B&B nodes | Runs | Model | Best known (any method) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| setA-01 | 20 | 80 | 40 | 0.92938 | 0.8 | Optimal | -- | 1.0 | 10 | arc-pc | 0.92938 |
| setA-02 | 30 | 150 | 45 | 0.54858 | 2.3 | Optimal | -- | 1.0 | 10 | arc-pc | 0.54858 |
| setA-03 | 50 | 250 | 20 | 0.94354 | 5.2 | Optimal | -- | 1.0 | 10 | arc-pc | 0.94354 |
| setA-04 | 50 | 250 | 200 | 0.50105 | 1801.0 | Not Optimal | 0.098 | 0.0 | 8 | arc-pc | 0.45912 |
| setA-05 | 100 | 396 | 100 | 0.11552 | 291.5 | Optimal | -- | 1.0 | 10 | arc-pc | 0.11552 |
| setA-06 | 100 | 500 | 500 | 0.09859 | 10.7 | Optimal* | -- | 1.0 | 1 | wp | 0.09859 |
| setA-07 | 100 | 500 | 800 | 0.90799 | 2.7 | Optimal* | -- | 0.0 | 1 | wp | 0.90799 |
| setA-08 | 150 | 654 | 200 | 0.3189 | 1.2 | Optimal* | -- | 0.0 | 1 | wp | 0.3189 |
| setA-09 | 150 | 750 | 200 | 0.50538 | 2.0 | Optimal* | -- | 1.0 | 1 | wp | 0.50538 |
| setA-10 | 150 | 966 | 1000 | 0.06957 | 300.1 | Not Optimal* | 0.018 | 0.0 | 1 | wp-cg-lns | 0.06957 |
| setA-11 | 200 | 1000 | 400 | 0.61354 | 32.2 | Optimal* | -- | 13.0 | 1 | wp | 0.61354 |
| setA-12 | 200 | 898 | 400 | 0.64008 | 6.3 | Optimal* | -- | 1.0 | 1 | wp | 0.64008 |
| setA-13 | 200 | 1000 | 2000 | 0.03889 | 300.2 | Not Optimal* | 0.001 | 0.0 | 1 | wp-cg-lns | 0.03889 |
| setA-14 | 250 | 1108 | 600 | 0.43421 | 0.5 | Not Optimal* | 0.024 | 1.0 | 1 | wp-cg | 0.43421 |
| setA-15 | 250 | 1250 | 600 | 0.82521 | 0.4 | Optimal* | -- | 0.0 | 1 | wp-cg | 0.82521 |
| setA-16 | 250 | 1452 | 4800 | 0.12295 | 115.7 | Optimal* | -- | 1.0 | 1 | wp-cg | 0.12295 |
| setA-17 | 300 | 1270 | 2000 | 0.42419 | 2.4 | Optimal* | -- | 1.0 | 1 | wp-cg | 0.42419 |
| setA-18 | 300 | 1500 | 2000 | 0.63337 | 1.3 | Optimal* | -- | 0.0 | 1 | wp-cg | 0.63337 |
| setA-19 | 300 | 1998 | 6000 | 0.06745 | 1800.2 | Not Optimal* | 0.027 | 632.0 | 1 | wp-cg | 0.06745 |
| setA-20 | 400 | 2000 | 6000 | 0.99131 | 4.9 | Optimal* | -- | 0.0 | 1 | wp-cg | 0.99131 |

Model `arc-pc`: arc-based MILP of the statement, split coefficients r from calculating_r.pdf. Rows marked * come from the waypoint model (restricted problem: at most one waypoint per demand) because the arc-based model does not fit in memory; their status and gap refer to that restricted problem. Time, gap and nodes are averages over the runs listed in column Runs. Last column: best MLU found by any method (waypoint model, column generation, LNS), for comparison with the arc-model row.
