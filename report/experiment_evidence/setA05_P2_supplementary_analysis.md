# SetA-05 P2: why the first runs failed and how the optimum was found and proved

This note explains the 2026-10-24 (V4) rerun of SetA-05 P2. The V3 official runs stayed at MLU 0.999986144 (the baseline, gap 0.8975). The analysis below found and proved the optimum **0.2049858752**. It led to a fix of the `local_search` heuristic. With the fix, the official 10-run rerun reached this value in all 10 runs and proved it in 5 (`final_configuration_summary.csv`: *Optimal*). Raw files of the analysis are in `improvement_results_2026-10-24/setA05_bound/`.

## Result

| | V3 official runs (superseded) | Analysis | V4 official rerun |
|---|---|---|---|
| Best MLU | 0.9999861440 | **0.2049858752** | **0.2049858752** (10/10 runs) |
| Lower bound | 0.2049858752 (after the budget only) | **0.2049858752** (node cut, LP) | **0.2049858752** (5/10 runs) |
| Status | Feasible – not proven optimal | optimal (proof below) | **Optimal** |
| Budget used at t = 1 (κ = 1) | 0 | 0 | 0 |
| Independent verifier (`verify_srpaths.py`) | verified | verified, `problems: []` | 10/10 verified |

## Why the baseline is at 0.99999

At t = 1, the volume of demand 19 (84 → 25) rises from 0.957 to 2.872. This equals the capacity of the direct arc 84 → 25 (2.872). With the direct path ⟨84, 25⟩, that arc is saturated. No other arc exceeds 0.205.

## Optimal solution

- Demand 19 uses ⟨84, 99, 25⟩ in **both** periods. Because its path is the same in both periods, it costs no budget.
- Every other demand keeps its direct path.
- Maximum utilization: 0.1668 at t = 0 (arc 40 → 73) and **0.2049858752** at t = 1 (arc 17 → 14).

## Optimality proof (independent of the solver)

At t = 1, node 17 has a single active out-arc, 17 → 14, with capacity 26.465. Every demand whose source is 17 must leave through this arc, whatever its waypoints. Their total volume is 5.425, so for any routing

  MLU ≥ 5.4249 / 26.4648 = 0.2049858…,

which equals the value reached. Two further checks give the same number:

- removing arc 17 → 14 disconnects those demands ("forced-arc" bound);
- the LP relaxation of the merged model, solved by HiGHS IPM, has optimum 0.2049858753 (primal–dual error 2·10⁻⁹, 347 s).

The same node-cut argument explains SetA-05 P1: node 83 receives 3.191 units through in-arcs of total capacity 27.624. That bound, 0.1155237, equals the official optimum.

## Why the V3 official runs missed it

- **Heuristic.** `local_search` (seed 1) supplied the MIP start in all full-arc runs. It changed a path in one period at a time. With κ = 1, every such move costs at least 3 segment changes (two distinct s–t segment paths always differ in at least 3 segments), so every move was rejected. The heuristic returned the direct paths. The move that was needed, changing demand 19 in both periods at once, was never tried.
- **MILP.** With presolve off (size rule) and 2.97 M columns, HiGHS did not finish the root LP within 3600 s, so its primal heuristics never ran.

## Fix

`local_search` now also tries, for each candidate path, changing all periods at once. The budget is checked for every affected transition. Results with the fixed heuristic:

- SetA-05 P2: **0.2049858752 in 1.8 s**.
- SetA-05 P1: 0.1155237446, the official optimum.
- Toy instance with budget 0: a new unit test requires the heuristic to reach the brute-force optimum.

## Official rerun with the fixed heuristic (V4, 2026-10-24)

Same protocol as before (3600 s, seeds 1–10, one thread per run). The only change was the patched `local_search` (`fix_local_search_joint.patch`, SHA-256 `2a7b3841…`). The 10 runs were spread over 5 parallel processes.

| Runs (seeds) | Status | MLU | LB | Solve time |
|---|---|---|---|---|
| 2, 3, 6, 7, 10 | Optimal | 0.2049858752 | 0.2049858752 | 120–189 s |
| 1, 4, 5, 8, 9 | time limit | 0.2049858752 | 0 | 3600 s |

Every run starts from the optimal MIP start. The time is spent on the root LP: dual simplex with presolve off, because the model has 2.97 M columns. That LP is highly degenerate, and its solve time depends strongly on the seed. Seed 2 finishes it in 1,665 iterations; seed 1 has not finished after 32,146. The seeds that fail are the same ones whose V3 runs never reached a bound.

## Supporting result: small budgets mean identical routings

- **Lemma.** Two distinct simple s–t segment paths differ in at least 3 segments. So at most ⌊κ(t)/3⌋ demands can change path between t − 1 and t.
- **Merged model.** When κ(t) < 3, routing is identical in all periods. Using one routing variable per demand for all periods, and dropping the budget variables, is then an exact reformulation.
- **Checks** (files in `improvement_results_2026-10-24/merge/`, explained in `GIAI_THICH_KET_QUA_CAI_TIEN.md`):
  - brute force on 2.88 M path pairs;
  - same optimum as the original model on SetA-01..03 with κ ∈ {0, 1, 2};
  - up to more than 100× faster where the original model timed out.
- **SetA-05 P2.** The merged model alone did not solve SetA-05 P2: its root LP was still unsolved after 3600 s with dual simplex. IPM solves the same LP in 347 s.
