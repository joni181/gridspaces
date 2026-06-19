#!/bin/zsh
set -euo pipefail

PID="$(pgrep -x GridSpacesAgent | head -n 1)"
if [[ -z "$PID" ]]; then
  echo "GridSpacesAgent is not running. Run ./scripts/run.sh first." >&2
  exit 1
fi

ps -o pid=,etime=,%cpu=,rss=,command= -p "$PID"
