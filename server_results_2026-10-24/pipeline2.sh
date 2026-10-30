#!/usr/bin/env bash
# Deadline-bounded official campaign (priority order). Re-running resumes:
# finished batches are skipped via v2_*.done markers, and each batch command resumes by itself.
set -u
B=/home/darkweb/network-model-test
R=$B/SOICT_mathematical_modelling
L=$B/logs
export PATH=$B/bin:$B/julia-1.13.1/bin:$PATH
export JULIA_DEPOT_PATH=$B/julia-depot
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
MIN_AVAIL_GB=${MIN_AVAIL_GB:-40}
DEADLINE=$(date -d '2026-10-23T00:00:00Z' +%s)   # stop experiments here; tables follow (user deadline 2026-10-23 01:00 UTC)
mkdir -p $L
cd $R || exit 1

log() { echo "$(date -Is) $*" | tee -a $L/pipeline.log; }
avail_gb() { awk '/MemAvailable/{print int($2/1048576)}' /proc/meminfo; }

ram_ok() {
    local a; a=$(avail_gb)
    { echo "--- free -h ($(date -Is)) before $1"; free -h; } >> $L/pipeline.log
    if [ "$a" -lt "$MIN_AVAIL_GB" ]; then
        log "STOP: MemAvailable=${a}G < ${MIN_AVAIL_GB}G before $1"
        exit 2
    fi
}

# run_batch <id> <pessimistic hours> <command>
run_batch() {
    local id=$1 est_h=$2; shift 2
    local cmd="$*"
    if [ -f $L/v2_$id.done ]; then log "V2 $id already complete, skipping"; return 0; fi
    local attempt rc left
    for attempt in 1 2 3; do
        left=$(( DEADLINE - $(date +%s) ))
        if [ $left -lt $(( est_h * 3600 )) ]; then
            log "V2 $id NOT STARTED: $((left / 3600))h left < ${est_h}h estimate (deadline rule)"
            return 1
        fi
        ram_ok "V2 $id"
        log "V2 $id START attempt=$attempt CMD: $cmd"
        echo "===== $(date -Is) attempt $attempt: $cmd" >> $L/v2_$id.log
        timeout --signal=TERM --kill-after=120 $left bash -c "$cmd" >> $L/v2_$id.log 2>&1
        rc=$?
        log "V2 $id END attempt=$attempt rc=$rc"
        if [ $rc -eq 0 ]; then touch $L/v2_$id.done; return 0; fi
        if [ $rc -eq 124 ] || [ $rc -eq 137 ]; then log "V2 $id stopped at deadline"; return 1; fi
    done
    log "V2 $id failed 3 times"
    return 1
}

log "V2 campaign start (deadline $(date -u -d @$DEADLINE -Is))"
run_batch p1_s01-03  1 "ORANGE_MAX_VARS=16000000 julia --project=orange orange/scripts/run_experiments.jl 1 1800 1 3 pc 1 10"
run_batch p2_s01-03 21 "ORANGE_MAX_VARS=10000000 julia --project=orange orange/scripts/run_experiments.jl 2 3600 1 3 pc 1 10"
run_batch p1_s04-05 11 "ORANGE_MAX_VARS=16000000 julia --project=orange orange/scripts/run_experiments.jl 1 1800 4 5 pc 1 10"
run_batch p2_s04-05 24 "ORANGE_MAX_VARS=10000000 julia --project=orange orange/scripts/run_experiments.jl 2 3600 4 5 pc 1 10"
if [ -f $L/v2_p1_s01-03.done ] && [ -f $L/v2_p2_s01-03.done ] && [ -f $L/v2_p1_s04-05.done ] && [ -f $L/v2_p2_s04-05.done ]; then
    run_batch wp_p1_s10 6 "julia --project=orange orange/scripts/run_official_wp.jl 1 1800 10 10 1 10" \
        && run_batch wp_p2_s07 2 "julia --project=orange orange/scripts/run_official_wp.jl 2 3600 7 7 1 10"
else
    log "V2 optional WP batches not started: priorities 1-4 not all complete"
fi

log "TABLES start"
julia --project=orange orange/scripts/official_tables.jl orange/results report > $L/tables.log 2>&1
rc=$?
log "TABLES end rc=$rc"
log "V2 PIPELINE FINISHED"
