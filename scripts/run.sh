#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/build.sh"

open -gj "$ROOT/.build/release/GridSpaces.app"
sleep 0.5
GRIDSPACES_APP="$ROOT/.build/release/GridSpaces.app" \
    "$ROOT/.build/release/gridspaces" open
