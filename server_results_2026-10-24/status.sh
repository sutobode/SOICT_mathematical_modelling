#!/usr/bin/env bash
# Read-only status of the official campaign.
B=/home/darkweb/network-model-test
L=$B/logs
echo "### pipeline.log (tail)"
tail -n ${1:-15} $L/pipeline.log
echo "### processes"
ps -u darkweb -o pid,etime,rss,args | grep -E 'pipeline2?\.sh|scripts/run_|runtests' | grep -v grep | cut -c1-160
echo "### memory"
free -h | head -2
latest=$(ls -t $L/batch*.log $L/v2_*.log 2>/dev/null | head -1)
if [ -n "$latest" ]; then
  echo "### $latest (last == lines)"
  grep -E '^==|^   ' "$latest" | tail -n 6
fi
ls $L/*.done 2>/dev/null
