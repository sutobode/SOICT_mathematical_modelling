#!/usr/bin/env bash
# Exact lexicographic runs (orange/scripts/run_lex_pathcount.jl, unchanged) in priority order,
# stopped at a hard deadline. Outputs stay in $B/lex, outside the official results.
set -u
B=/home/darkweb/network-model-test
R=$B/SOICT_mathematical_modelling
X=$B/lex
export PATH=$B/bin:$B/julia-1.13.1/bin:$PATH
export JULIA_DEPOT_PATH=$B/julia-depot
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
DEADLINE=${DEADLINE:?}
mkdir -p $X
cd $R || exit 1
log() { echo "$(date -Is) $*" | tee -a $X/lex.log; }

run_lex() {   # name P seconds-per-rank
    local name=$1 P=$2 per_rank=$3
    local tag=$name-P$P
    [ -f $X/$tag.done ] && { log "LEX $tag already done"; return 0; }
    local left=$(( DEADLINE - $(date +%s) ))
    [ $left -le 60 ] && { log "LEX $tag NOT STARTED: deadline reached"; return 1; }
    log "LEX $tag START per_rank=${per_rank}s left=${left}s"
    local t0=$(date +%s)
    timeout --signal=TERM --kill-after=60 $left \
        julia --project=orange orange/scripts/run_lex_pathcount.jl project/setA/$name $P $per_rank $X/$tag-lex-srpaths.json \
        > $X/$tag.out 2>&1
    local rc=$?
    log "LEX $tag END rc=$rc wall=$(( $(date +%s) - t0 ))s"
    [ $rc -eq 0 ] && touch $X/$tag.done
    return $rc
}

log "LEX chain start, deadline $(date -u -d @$DEADLINE -Is)"
run_lex setA-01 1 1800
run_lex setA-01 2 3600
run_lex setA-02 1 1800
log "LEX chain FINISHED"
