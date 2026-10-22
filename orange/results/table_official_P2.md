# Table 2 -- time periods 0 and 1 with budget, limit 3600 s (step 9)

| Instance | Vertices | Links | Demands | Best objective (MLU) | CPU time (s) | Status | Gap | B&B nodes | Runs | Model | Best known (any method) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| setA-01 | 20 | 80 | 40 | 0.92938 | 39.3 | Optimal | -- | 1.0 | 10 | arc-pc | 0.92938 |
| setA-02 | 30 | 150 | 45 | 0.90307 | 2869.9 | Optimal 9/10 | 0.1 | 1.0 | 10 | arc-pc | 0.90307 |
| setA-03 | 50 | 250 | 20 | 0.94354 | 1131.2 | Optimal 8/10 | 0.2 | 1.0 | 10 | arc-pc | 0.94354 |
| setA-04 | 50 | 250 | 200 | 0.58857 | 4034.7 | Not Optimal | 0.78 | 0.0 | 9 | arc-pc | 0.58281 |
| setA-05 | 100 | 396 | 100 | 0.20499 | 3983.1 | Optimal 1/9 | 0.89 | 0.0 | 9 | arc-pc | 0.20499 |
| setA-06 | 100 | 500 | 500 | 0.14085 | 2223.5 | Not Optimal (1-wp) | 0.3 | 0.0 | 1 | wp-cg | 0.14085 |
| setA-07 | 100 | 500 | 800 | 0.90799 | 3.2 | Optimal (1-wp) | -- | 0.0 | 1 | wp-cg | 0.90799 |
| setA-08 | 150 | 654 | 200 | 0.3189 | 8.5 | Optimal (1-wp) | -- | 1.0 | 1 | wp-cg | 0.3189 |
| setA-09 | 150 | 750 | 200 | 0.84965 | 0.3 | Not Optimal (1-wp) | 0.41 | 0.0 | 1 | wp-cg | 0.84965 |
| setA-10 | 150 | 966 | 1000 | 0.1087 | 300.6 | Not Optimal (1-wp) | 0.37 | 0.0 | 1 | wp-cg-lns | 0.1087 |
| setA-11 | 200 | 1000 | 400 | 0.78579 | 1.3 | Not Optimal (1-wp) | 0.22 | 0.0 | 1 | wp-cg | 0.78579 |
| setA-12 | 200 | 898 | 400 | 0.87987 | 1.3 | Not Optimal (1-wp) | 0.27 | 0.0 | 1 | wp-cg | 0.87987 |
| setA-13 | 200 | 1000 | 2000 | 0.07692 | 302.0 | Not Optimal (1-wp) | 0.49 | 0.0 | 1 | wp-cg-lns | 0.07692 |
| setA-14 | 250 | 1108 | 600 | 0.53315 | 78.0 | Not Optimal (1-wp) | 0.2 | 37.0 | 1 | wp-cg | 0.53315 |
| setA-15 | 250 | 1250 | 600 | 0.8987 | 1.3 | Not Optimal (1-wp) | 0.082 | 0.0 | 1 | wp-cg | 0.8987 |
| setA-16 | 250 | 1452 | 4800 | 0.51639 | 0.0 | Not Optimal (1-wp) | 0.76 | -- | 1 | wp-cg-lns-fast | 0.51639 |
| setA-17 | 300 | 1270 | 2000 | 0.42419 | 527.3 | Optimal (1-wp) | -- | 1.0 | 1 | wp-cg | 0.42419 |
| setA-18 | 300 | 1500 | 2000 | 1.0 | 17.2 | Not Optimal (1-wp) | 0.37 | 0.0 | 1 | wp-cg | 1.0 |
| setA-19 | 300 | 1998 | 6000 | 0.10258 | 0.0 | Not Optimal (1-wp) | 0.36 | -- | 1 | wp-cg-lns-fast | 0.10258 |
| setA-20 | 400 | 2000 | 6000 | 0.99131 | 597.5 | Optimal (1-wp) | -- | 0.0 | 1 | wp-cg | 0.99131 |

Model `arc-pc`: arc-based MILP of the statement, split coefficients r from calculating_r.pdf. Rows whose status ends with (1-wp) come from the waypoint model (restricted problem: at most one waypoint per demand, hence at most two segments, while maxSeg = 6) because the arc-based model does not fit in memory; their status and gap refer to that restricted problem only and are NOT optimality statements for the original problem; the value is a valid upper bound on the original optimum. Gap of a (1-wp) row = 1 - LB/UB with LB from the full waypoint model or the column-generation LP at t=0 (for Table 2 the t=0 bound is also a valid bound for t=0,1). Time, gap and nodes are averages over the runs listed in column Runs. Last column: best MLU found by any method (waypoint model, column generation, LNS), for comparison with the arc-model row.
