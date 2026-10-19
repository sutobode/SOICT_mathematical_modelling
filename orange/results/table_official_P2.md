# Table 2 -- time periods 0 and 1 with budget, limit 3600 s (step 9)

| Instance | Vertices | Links | Demands | Best objective (MLU) | CPU time (s) | Status | Gap | B&B nodes | Runs | Model | Best known (any method) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| setA-01 | 20 | 80 | 40 | 0.92938 | 39.3 | Optimal | -- | 1.0 | 10 | arc-pc | 0.92938 |
| setA-02 | 30 | 150 | 45 | 0.90307 | 2625.3 | Optimal | -- | 1.0 | 3 | arc-pc | 0.90307 |
| setA-03 | 50 | 250 | 20 | 0.94354 | 277.9 | Optimal | -- | 1.0 | 2 | arc-pc | 0.94354 |
| setA-04 | 50 | 250 | 200 | 0.58281 | 59.6 | Optimal* | -- | 1.0 | 1 | wp | 0.58281 |
| setA-05 | 100 | 396 | 100 | 0.20499 | 44.5 | Optimal* | -- | 1.0 | 1 | wp | 0.20499 |
| setA-06 | 100 | 500 | 500 | 0.14085 | 2223.5 | Not Optimal* | -- | 0.0 | 1 | wp-cg | 0.14085 |
| setA-07 | 100 | 500 | 800 | 0.90799 | 3.2 | Not Optimal* | -- | 0.0 | 1 | wp-cg | 0.90799 |
| setA-08 | 150 | 654 | 200 | 0.3189 | 8.5 | Not Optimal* | -- | 1.0 | 1 | wp-cg | 0.3189 |
| setA-09 | 150 | 750 | 200 | 0.84965 | 0.3 | Not Optimal* | -- | 0.0 | 1 | wp-cg | 0.84965 |
| setA-10 | 150 | 966 | 1000 | 1.0 | 3600.3 | Not Optimal* | -- | 0.0 | 1 | wp-cg | 1.0 |
| setA-11 | 200 | 1000 | 400 | 0.78579 | 1.3 | Not Optimal* | -- | 0.0 | 1 | wp-cg | 0.78579 |
| setA-12 | 200 | 898 | 400 | 0.87987 | 1.3 | Not Optimal* | -- | 0.0 | 1 | wp-cg | 0.87987 |
| setA-13 | -- | -- | -- | -- | -- | no result | -- | -- | 0 | -- | -- |
| setA-14 | -- | -- | -- | -- | -- | no result | -- | -- | 0 | -- | -- |
| setA-15 | -- | -- | -- | -- | -- | no result | -- | -- | 0 | -- | -- |
| setA-16 | -- | -- | -- | -- | -- | no result | -- | -- | 0 | -- | -- |
| setA-17 | -- | -- | -- | -- | -- | no result | -- | -- | 0 | -- | -- |
| setA-18 | 300 | 1500 | 2000 | 1.0 | 18.4 | Not Optimal* | -- | 0.0 | 1 | wp-cg-pc | 1.0 |
| setA-19 | -- | -- | -- | -- | -- | no result | -- | -- | 0 | -- | -- |
| setA-20 | 400 | 2000 | 6000 | 0.99131 | 273.7 | Not Optimal* | -- | 0.0 | 1 | wp-cg-pc | 0.99131 |

Model `arc-pc`: arc-based MILP of the statement, split coefficients r from calculating_r.pdf. Rows marked * come from the waypoint model (restricted problem: at most one waypoint per demand) because the arc-based model does not fit in memory; their status and gap refer to that restricted problem. Time, gap and nodes are averages over the runs listed in column Runs. Last column: best MLU found by any method (waypoint model, column generation, LNS), for comparison with the arc-model row.
