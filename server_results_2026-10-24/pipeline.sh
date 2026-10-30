#!/usr/bin/env bash
# Official experiment campaign driver. Re-running this script resumes: finished
# steps are skipped via *.done markers, and each batch command resumes by itself.
set -u
B=/home/darkweb/network-model-test
R=$B/SOICT_mathematical_modelling
L=$B/logs
export PATH=$B/bin:$B/julia-1.13.1/bin:$PATH
export JULIA_DEPOT_PATH=$B/julia-depot
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
MIN_AVAIL_GB=${MIN_AVAIL_GB:-60}
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

if [ ! -f $L/step0.done ]; then
    log "STEP0 branch=$(git branch --show-current) commit=$(git rev-parse HEAD)"
    if [ -n "$(git status --short)" ]; then log "STOP: working tree not clean"; git status --short >> $L/pipeline.log; exit 1; fi
    julia --version | tee -a $L/pipeline.log
    log "instantiate start"
    julia --project=orange -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()' > $L/00_instantiate.log 2>&1 \
        || { log "STOP: Pkg.instantiate failed"; exit 1; }
    log "tests start"
    julia --project=orange orange/test/runtests.jl > $L/00_tests.log 2>&1
    rc=$?
    log "tests end rc=$rc"
    [ $rc -eq 0 ] || { log "STOP: tests failed"; exit 1; }
    if [ -n "$(git status --short)" ]; then log "STOP: tests left the working tree dirty"; git status --short >> $L/pipeline.log; exit 1; fi
    if [ ! -f orange/results/environment-server.txt ]; then
        {
          echo "Commit:"
          git rev-parse HEAD
          echo
          julia --version
          echo
          lscpu
          echo
          free -h
        } > orange/results/environment-server.txt
    fi
    touch $L/step0.done
    log "STEP0 done"
fi

run_batch() {
    local id=$1; shift
    local cmd="$*"
    if [ -f $L/batch$id.done ]; then log "BATCH $id already complete, skipping"; return 0; fi
    local attempt rc
    for attempt in 1 2 3; do
        ram_ok "batch $id"
        log "BATCH $id START attempt=$attempt CMD: $cmd"
        echo "===== $(date -Is) attempt $attempt: $cmd" >> $L/batch$id.log
        bash -c "$cmd" >> $L/batch$id.log 2>&1
        rc=$?
        log "BATCH $id END attempt=$attempt rc=$rc"
        if [ $rc -eq 0 ]; then touch $L/batch$id.done; return 0; fi
    done
    log "STOP: batch $id failed 3 times"
    exit 3
}

run_batch 1 "ORANGE_MAX_VARS=16000000 julia --project=orange orange/scripts/run_experiments.jl 1 1800 1 9 pc 1 10"
run_batch 2 "ORANGE_MAX_VARS=16000000 julia --project=orange orange/scripts/run_experiments.jl 1 1800 11 12 pc 1 10"
run_batch 3 "ORANGE_MAX_VARS=10000000 julia --project=orange orange/scripts/run_experiments.jl 2 3600 1 6 pc 1 10"
run_batch 4 "ORANGE_MAX_VARS=10000000 julia --project=orange orange/scripts/run_experiments.jl 2 3600 8 9 pc 1 10"
run_batch 5 "julia --project=orange orange/scripts/run_official_wp.jl 1 1800 10 10 1 10"
run_batch 6 "julia --project=orange orange/scripts/run_official_wp.jl 1 1800 13 20 1 10"
run_batch 7 "julia --project=orange orange/scripts/run_official_wp.jl 2 3600 7 7 1 10"
run_batch 8 "julia --project=orange orange/scripts/run_official_wp.jl 2 3600 10 20 1 10"

log "TABLES start"
julia --project=orange orange/scripts/official_tables.jl orange/results report > $L/tables.log 2>&1
rc=$?
log "TABLES end rc=$rc"
[ $rc -eq 0 ] || { log "STOP: table generation failed"; exit 4; }
log "PIPELINE FINISHED"
