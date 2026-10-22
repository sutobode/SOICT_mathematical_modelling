# T-ASR official experiment campaign — audit

All numbers below come from the raw campaign outputs (`server_results_2026-10-22/`: per-run CSVs, HiGHS solver logs, batch logs, `pipeline.log`) and from the source code at the experiment commit. Nothing here was entered by hand. The derived files in this folder are produced by one script from those inputs.

## 1. Experiment commit

| Item | Value |
|---|---|
| Branch on server | `hung` |
| Commit | `0da1a520dc086e2a7c3f2f74a6212205376680be` ("Enhance official experiment scripts and reporting") |
| Working tree at start | **clean** — the driver ran `git status --short` before the tests and would have stopped otherwise (`pipeline.log`: `STEP0 ... done`, no STOP) |
| Result schema | `schema_version = 2` in all 120 official rows (`OFFICIAL_SCHEMA_VERSION = "2"`, `orange/src/reporting.jl:2`); `experiment = official` in all rows |
| Campaign window (UTC) | 2026-10-20 15:52 → 2026-10-22 11:52 (tables generated 11:52:42) |
| Later code changes | On the same line (`hung`/`kien`) only `ff7be61` (parallel-arc support in `ecmp.jl`/`io.jl`). At 0da1a52, `read_instance` raises an error on parallel arcs, and every run succeeded, so that change cannot alter these results. `origin/main` is a separate history without the official scripts. |

Fixes present at 0da1a52 (code location; test that passed in `logs/00_tests.log`):

| Fix | Evidence |
|---|---|
| One solver-time budget across retries | `_solve_with_acyclic_retry`: `remaining = total_limit - first.t` (`orange/src/experiment.jl:78-99`); test *official retry shares time and accumulates nodes* 6/6 |
| B&B nodes accumulated across retries | `_sum_attempt_metric(first.nodes, second.nodes)` (same function) |
| Verified route/load artifacts | `verify_official_artifact` → `verify_srpaths.py` (`official_common.jl:100`); test *official load artifact is independently verified* 4/4 |
| Deterministic restricted candidates | official `candidate_seed = 1`, `extend_start_candidates = false` (`experiment.jl` `run_wp_instance`); test *official restricted candidates are run-independent* 5/5 |
| Candidate SHA-256 fingerprint | `candidate_fingerprint` (`wpmodel.jl:57-67`, `sha256`), re-checked after model build; test *restricted aggregation requires the candidate fingerprint* 3/3 |
| Schema-v2 isolation | aggregation keeps only `schema_version == "2"` rows (`official_common.jl:47`); test *legacy and malformed rows cannot enter official aggregation* 2/2 |
| Resume | `run_official_with_resume` (`official_common.jl:140`); observed in practice: 30 P=1 and 30 P=2 runs re-validated and `skipped` |
| Atomic artifact publication | `_write_artifacts_atomic`: write to `tempname`, then `mv` (`experiment.jl:102-116`) |
| `ORANGE_MAX_VARS` | `configured_max_vars` (`experiment.jl:4-9`), used by `run_experiments.jl:17` |

**EXPERIMENT CODE VERSION: CONFIRMED**

## 2. Environment

See `experiment_environment.txt`. In short:
- **Host:** Ubuntu 24.04.3 LTS on a VMware VM, Intel Xeon Silver 4314 (16 vCPU), 125 GiB RAM (117 GiB available at start).
- **Software:** Julia 1.13.1, JuMP 1.32.1, MOI 1.54.0, HiGHS 1.15.1 (HiGHS.jl 1.26.0).
- **Settings:** single-threaded throughout, `mip_rel_gap = 1e-6`, `random_seed = run id`, runs executed strictly one after another.

## 3. Baseline definition (`mlu_base` / `baseline_mlu`)

Code: `base_mlu(inst, rs, P) = max_utilization(inst, rs, direct_paths(inst, P), P)` (`orange/src/verify.jl:27`). It is called in `run_instance` (`experiment.jl:155-156`) and `run_wp_instance` with `rs = [build_r(inst, p; mode=:pathcount) for p in 1:P]`.

- **Route per demand:** `direct_paths` gives every demand d in every period p the single segment `<s_d, t_d>`, i.e. no waypoint and no use of the segment budget.
- **Traffic split:** segment `(u, v)` in period p is routed on the shortest-path DAG of `G_p` (Dijkstra on link metrics ω). The fraction on arc a=(x,y) is `S[u,x]·S[y,v] / S[u,v]`, where S counts shortest paths (`pathcount_split`, `orange/src/ecmp.jl`). This is the official `pathcount` mode, not per-hop ECMP.
- **Topology per period:** `G_p` excludes the arcs listed in the scenario's interventions for period p (`inst.down[p]`, `io.jl`). Interventions are therefore included, and the routing is recomputed independently in each period.
- **Volumes:** `vol[d, p]` from the traffic matrix for period p.
- **Single value for P=2:** the maximum over both periods of the maximum arc utilisation.

Report-ready definition:

> For each period p ∈ {1..P}, let G_p be the network without the links taken down in p and let r^p_{uv}(a) be the path-count shortest-path split of segment (u,v) on arc a in G_p. The baseline routes every demand d directly on its own segment ⟨s_d,t_d⟩:
> **MLU_base = max_{p} max_{a ∈ A_p} ( Σ_d vol_{d,p} · r^p_{s_d t_d}(a) ) / c_a.**

Improvement is reported as `(MLU_base − MLU) / MLU_base × 100`. Baseline values slightly above 1 (for example 1.0000006861 for setA-01) are genuine overloads computed by the code.

## 4. Completed scope

All configurations below have runs 1..10 present and valid. In every row: `routing_mode = pathcount`, `objective_mode = pure_mlu`, `maxSeg = 6`, schema 2, `check = ok`, and the independent verifier returns `verified` for all 120 runs (`evidence/verify_all_runs.csv`).

**A. Full original T-ASR model (`full_arc`)**

| Instance | \|V\| | \|A\| | \|D\| | P | Time limit |
|---|---|---|---|---|---|
| setA-01 | 20 | 80 | 40 | 1, 2 | 1800 / 3600 s |
| setA-02 | 30 | 150 | 45 | 1, 2 | 1800 / 3600 s |
| setA-03 | 50 | 250 | 20 | 1, 2 | 1800 / 3600 s |
| setA-04 | 50 | 250 | 200 | 1, 2 | 1800 / 3600 s |
| setA-05 | 100 | 396 | 100 | 1, 2 | 1800 / 3600 s |

**B. Restricted waypoint model (`restricted_waypoint`, at most one waypoint per demand).** These are feasible upper bounds, **not** original-problem optima.

| Instance | P | Time limit | K (candidates per demand) | Binaries | Candidate SHA-256 |
|---|---|---|---|---|---|
| setA-10 | 1 | 1800 s | 148 (all n−2 nodes) | 149,000 | `2c557840fb426fd35a4f9b3ddce39f0650d8efc70e9a27d368c5b2d31bf9e0b6` |
| setA-07 | 2 | 3600 s | 98 (all n−2 nodes) | 158,400 | `ec28924ef95db458b4371d0d1cdfc600b2187dc9c42c7f96efbf8f20e995d9dc` |

The fingerprint is identical across the 10 runs of each configuration.

**Not run (outside the agreed scope):**
- P=1: setA-06..09, setA-11..20 (setA-10 only as restricted).
- P=2: setA-06, setA-08..20 (setA-07 only as restricted).
- No configuration is partially complete. One run (setA-04 P=1 run 1) was interrupted by the driver switch at 16:17 UTC on 20/10 before it wrote any row. It was re-run from scratch later.

## 5. Status-semantics audit — **FAIL** (generated official tables)

Logic: in `best_known_records` (`orange/scripts/official_common.jl`, around line 205):
```julia
record["status"] = model_type == "full_arc" && record["original_problem_optimal"] == "true" ?
                   "Optimal" : "Feasible upper bound (restricted)"
```
1. Every full-arc configuration that is not optimal is labelled *restricted*.
2. In `summarize_official_rows` (`orange/src/reporting.jl`), the best run is chosen by `(mlu, run id)`. When all runs tie on MLU, the run with the lowest id wins even if it did not prove optimality, and the configuration status follows only that run.

Wrong rows in `table_official_P1/P2.{csv,md,tex}` and `best_known.csv`:

| Row | Generated | Correct |
|---|---|---|
| setA-04 P1 | Feasible upper bound (restricted) | Feasible – not proven optimal |
| setA-02 P2 | Feasible upper bound (restricted) | **Optimal**: runs 2, 3, 7, 10 prove LB = UB = 0.9030747093 within 133–282 s; runs 1, 4, 5, 6, 8, 9 reach the same incumbent but hit the limit |
| setA-04 P2 | Feasible upper bound (restricted) | Feasible – not proven optimal |
| setA-05 P2 | Feasible upper bound (restricted) | Feasible – not proven optimal (and see §6: not valid under the protocol) |
| setA-10 P1, setA-07 P2 (restricted) | Feasible upper bound (restricted) | correct; but the `Optimal runs` column shows 10/10 for setA-07 P2, which is optimality **of the restricted model only** |

`final_configuration_summary.csv` applies the expected semantics and should be used instead of the generated tables until the aggregation code is fixed.

## 6. Timing audit — **TIMING DATA SAFE FOR REPORT: NO** (two configurations)

Scan of all 120 runs:
- 74 runs within the limit.
- 38 runs with an expected shutdown overrun of ≤ 10 s.
- 8 runs over the limit, all in P=2 setA-04/05.

Every full-arc run made exactly **one** solver attempt: there is no `-acyclic` log and no `(acyclic)` check. So the retry budget logic was never triggered, and nodes needed no accumulation (all 0: these runs stayed at the root node).

| Instance | P | Run | CSV solve_time | Wall-clock* | Attempts | First attempt | Retry | Incumbent found at | Classification |
|---|---|---|---|---|---|---|---|---|---|
| setA-04 | 2 | 1 | 29991.4 s | **887 s** | 1 | limit 3600 s; HiGHS clock jumps from 284.7 s to 29990.9 s between consecutive log lines | — | MIP start (0 s); LB at 147 s | OTHER (solver clock discontinuity; run ended early) |
| setA-04 | 2 | 3 | 3714.2 s | 3781 s | 1 | limit 3600 s | — | MIP start; LB at 147 s | REAL_PROTOCOL_VIOLATION (+114 s, result-neutral) |
| setA-04 | 2 | 8 | 4549.4 s | 4618 s | 1 | limit 3600 s | — | MIP start; LB early | REAL_PROTOCOL_VIOLATION (+949 s, result-neutral) |
| setA-05 | 2 | 2 | 6213.9 s | 6364 s | 1 | limit 3600 s; silent from 133 s to 6213 s | — | **6212.8 s** (0.32308) | REAL_PROTOCOL_VIOLATION |
| setA-05 | 2 | 3 | 6394.5 s | 6546 s | 1 | limit 3600 s | — | **6393.3 s** (0.32308) | REAL_PROTOCOL_VIOLATION |
| setA-05 | 2 | 6 | 6978.7 s | 7130 s | 1 | limit 3600 s | — | **6977.5 s** (0.29814 = reported best) | REAL_PROTOCOL_VIOLATION |
| setA-05 | 2 | 7 | 6435.9 s | 6624 s | 1 | limit 3600 s | — | MIP start (0.99999) | REAL_PROTOCOL_VIOLATION |
| setA-05 | 2 | 10 | 6334.1 s | 6489 s | 1 | limit 3600 s | — | **6333.1 s** (0.32308) | REAL_PROTOCOL_VIOLATION |

\* Wall-clock is measured between consecutive run-start timestamps in the batch log. It includes model build, the heuristic start and artifact I/O (about 70–150 s for these models).

Observations from the solver logs:
- In the setA-05 P2 overruns, HiGHS prints nothing between about 130–175 s and 6200–7000 s. It then reports a new incumbent (source `C`) together with "Time limit reached", i.e. a single long root-node phase that did not honour the time limit.
- The only full-arc models with presolve switched off (> 1.2 M variables) are exactly P=2 setA-04 and setA-05. This is a correlation, not an established cause.

Consequences:
- **setA-05 P2:** within 3600 s every run's incumbent was the MIP start 0.999986144, which equals the baseline. All improvements, including the reported best 0.29814, were found after the budget. Its MLU result is **not valid under the protocol**. Its LB 0.2049858752 was reached at 114–175 s, within the budget.
- **setA-04 P2:** MLU 0.5885746231 and LB 0.5811439394 are identical in all 10 runs and were reached before 3600 s, so they are reportable. Its average solve time (6346 s) is not.

## 7. Configurations safe to report

Fully safe (MLU, bound, status and timing): P=1 setA-01..05, P=2 setA-01..03, restricted setA-10 P1 and setA-07 P2 (as restricted upper bounds).

Partially safe: **setA-04 P2**. MLU, LB and status (*Feasible – not proven optimal*) are safe; the runtime statistics are not.

## 8. Configurations requiring rerun

- **setA-05 P2:** required. The budget must first be enforced effectively, because the same seed with single-threaded HiGHS can be expected to repeat the same long root phase.
- **setA-04 P2:** only if its average/median runtime is to be reported.

No other configuration is affected.

## 9. Known limitations

- The generated official tables carry wrong status labels (§5). Use `final_configuration_summary.csv`.
- The heuristic start (`local_search`, fixed seed 1) produced the final incumbent in 96/100 full-arc runs; the MILP's contribution within the budget is the lower bound or optimality proof. Run-to-run variation therefore comes only from HiGHS' `random_seed`.
- Restricted results bound the original optimum from above only; their gaps are gaps of the restricted model.
- The experiments ran in a VMware VM on a shared server; other users' jobs were running. CPU contention was not measured.
- HiGHS' reported `solve_time` can be unreliable (setA-04 P2 run 1). Wall-clock evidence is provided in `final_run_level_results.csv`.
- Only 5 instances were solved with the full model, plus 2 restricted. Scalability conclusions are limited to this range (≤ 2.97 M columns).
