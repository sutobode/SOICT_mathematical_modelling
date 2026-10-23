Raw evidence copied unchanged from server_results_2026-10-24 (campaign outputs downloaded 2026-10-23):
- pipeline.log, v3_p2_s05.log, v3_p2_s04.log: driver and rerun batch logs (UTC); 00_tests.log / v3_tests.log: test suites
- fix_time_limit_status.patch (SHA-256 ff5040ef...): the fix applied on top of 0da1a52; server_working_tree.diff: server diff
- verify_all_runs.csv: independent verify_srpaths.py result for all 120 final official runs
- solverlogs/*-budget.json: budget-guard record of each rerun run; solverlogs/*.log: truncated and comparison runs
- superseded_first_campaign/: first-campaign anomalies (setA-04 P2 r1 clock jump; setA-05 P2 r6 incumbent after the budget)
- generated_official_tables/: final tables exactly as produced by official_tables.jl (with the status fix)