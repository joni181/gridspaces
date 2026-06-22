# GridSpaces v0.1 verification

Automated coverage checks config defaults/validation, configured placement, reserved
empty tiles, overflow filtering, gap skipping, edge wrapping, overflow navigation,
and the ungridded headless-switch fallback.

Manual checks on a machine running AeroSpace:

- `gridspaces open` shows the popup and highlights the focused workspace.
- `h/j/k/l` and arrows move only the highlight; `Enter` focuses it; `Esc` cancels.
- A configured key under `[keys.workspaces]` focuses its workspace and closes the popup.
- Direct workspace keys are case-insensitive; modified variants do not trigger them.
- Navigation and action keys take precedence over colliding direct workspace keys.
- `x` asks for confirmation before closing the highlighted workspace's windows.
- `Alt+h/j/k/l` moves all windows into an empty adjacent workspace or swaps window sets with an occupied adjacent workspace; the highlight follows the source contents.
- Workspace-content movement skips configured gaps, does not wrap, and is a no-op for overflow workspaces.
- Holding only `Alt` shakes the tiles; holding `Alt+Ctrl` does not. Reduce Motion uses static emphasis.
- `Shift+h/j/k/l` moves the highlighted workspace between displays and preserves focus.
- `gridspaces focus --direction right` switches without opening the popup.
- Occupied unconfigured workspaces appear in one overflow row.
- On one display, move commands are silent no-ops and all outlines use one color.
- While idle, `./scripts/measure.sh` shows near-zero CPU and no AeroSpace polling.

The close-all, live workspace exchange, and multi-monitor checks are intentionally
user-run because they mutate live windows or require display hardware. The exchange
algorithm has automated coverage for empty moves, occupied swaps, vanished windows,
and rollback after a partial command failure.

Measured on June 18, 2026 after a release build: the resident agent used 0.0% CPU
while idle and approximately 69 MB RSS after opening and closing the grid. Opening
performed one fresh AeroSpace state read; no periodic reads occurred afterward.
