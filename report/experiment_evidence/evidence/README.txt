Raw evidence copied unchanged from the campaign outputs (server_results_2026-10-22):
- pipeline.log, v2_p2_s04-05.log, 00_tests.log, tables.log: driver/batch/test logs (timestamps in UTC)
- verify_all_runs.csv: independent verify_srpaths.py result for all 120 official runs (instance,P,model,run,result)
- environment-server.txt: lscpu / free -h / commit written at campaign start
- solverlogs/: HiGHS logs of every anomalous P2 run plus normal comparison runs
  (setA-04 P2 r2; setA-05 P2 r1; setA-02 P2 r1 = time limit, r2 = proven optimal)
- generated_official_tables/: the tables exactly as produced by official_tables.jl (contain the status-label bug described in experiment_audit.md section 5)
