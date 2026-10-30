#!/usr/bin/env bash
# Rerun of setA-05 and setA-04 (P=2, full arc) with the time-budget guard and the fixed status aggregation.
# Re-running this script resumes: the old rows of these two configurations are moved to an archive once, so
# the runners' normal resume re-solves exactly the missing runs (no ORANGE_FORCE_RESTART needed).
set -u
B=/home/darkweb/network-model-test
R=$B/SOICT_mathematical_modelling
L=$B/logs
A=$B/archive_superseded_2026-10-23
export PATH=$B/bin:$B/julia-1.13.1/bin:$PATH
export JULIA_DEPOT_PATH=$B/julia-depot
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
MIN_AVAIL_GB=${MIN_AVAIL_GB:-40}
cd $R || exit 1

log() { echo "$(date -Is) $*" | tee -a $L/pipeline.log; }
avail_gb() { awk '/MemAvailable/{print int($2/1048576)}' /proc/meminfo; }

if [ ! -f $L/v3_setup.done ]; then
    log "V3 setup: base $(git rev-parse HEAD) + patch $(sha256sum $L/fix_time_limit_status.patch | cut -c1-64)"
    grep -q 'TEST_EXIT=0' $L/v3_tests.log || { log "V3 STOP: tests did not pass (see logs/v3_tests.log)"; exit 1; }
    mkdir -p $A/orange/results/solverlogs
    for c in setA-05-P2 setA-04-P2; do
        for f in orange/results/$c-official-pc-r*; do [ -e "$f" ] && mv -n "$f" "$A/orange/results/"; done
        for f in orange/results/solverlogs/$c-official-pc-r*; do [ -e "$f" ] && mv -n "$f" "$A/orange/results/solverlogs/"; done
    done
    log "V3 archived $(find $A -type f | wc -l) superseded files to $A"
    touch $L/v3_setup.done
fi

run_batch() {
    local id=$1; shift
    local cmd="$*" attempt rc a
    if [ -f $L/v3_$id.done ]; then log "V3 $id already complete, skipping"; return 0; fi
    for attempt in 1 2 3; do
        a=$(avail_gb)
        { echo "--- free -h ($(date -Is)) before V3 $id"; free -h; } >> $L/pipeline.log
        [ "$a" -lt "$MIN_AVAIL_GB" ] && { log "V3 STOP: MemAvailable=${a}G < ${MIN_AVAIL_GB}G before $id"; exit 2; }
        log "V3 $id START attempt=$attempt CMD: $cmd"
        echo "===== $(date -Is) attempt $attempt: $cmd" >> $L/v3_$id.log
        bash -c "$cmd" >> $L/v3_$id.log 2>&1
        rc=$?
        log "V3 $id END attempt=$attempt rc=$rc"
        [ $rc -eq 0 ] && { touch $L/v3_$id.done; return 0; }
    done
    log "V3 STOP: $id failed 3 times"
    exit 3
}

run_batch p2_s05 "ORANGE_MAX_VARS=10000000 julia --project=orange orange/scripts/run_experiments.jl 2 3600 5 5 pc 1 10"
run_batch p2_s04 "ORANGE_MAX_VARS=10000000 julia --project=orange orange/scripts/run_experiments.jl 2 3600 4 4 pc 1 10"

log "V3 TABLES start"
julia --project=orange orange/scripts/official_tables.jl orange/results report > $L/v3_tables.log 2>&1
log "V3 TABLES end rc=$?"
log "V3 PIPELINE FINISHED"
