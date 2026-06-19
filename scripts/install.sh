#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/build.sh"

APP_DIR="$HOME/Applications"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$APP_DIR" "$BIN_DIR"
rm -rf "$APP_DIR/GridSpaces.app"
cp -R "$ROOT/.build/release/GridSpaces.app" "$APP_DIR/GridSpaces.app"
cp "$ROOT/.build/release/gridspaces" "$BIN_DIR/gridspaces"

echo "Installed GridSpaces.app to $APP_DIR"
echo "Installed gridspaces to $BIN_DIR"
echo "Ensure $BIN_DIR is on PATH, then run: gridspaces open"
