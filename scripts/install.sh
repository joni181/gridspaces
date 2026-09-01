#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/build.sh"

APP_DIR="$HOME/Applications"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$APP_DIR" "$BIN_DIR"
pkill -x GridSpacesAgent 2>/dev/null || true
rm -rf "$APP_DIR/GridSpaces.app"
cp -R "$ROOT/.build/release/GridSpaces.app" "$APP_DIR/GridSpaces.app"
cp "$ROOT/.build/release/gridspaces" "$BIN_DIR/gridspaces"
open -gj "$APP_DIR/GridSpaces.app"

echo "Installed GridSpaces.app to $APP_DIR"
echo "Installed gridspaces to $BIN_DIR"
echo "Restarted GridSpaces using the installed app"
