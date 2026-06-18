## 1. Project scaffolding

- [ ] 1.1 Create the Swift project: a macOS app target (`LSUIElement` menu-bar agent) and a bundled `gridspaces` CLI target, with a shared core module
- [ ] 1.2 Add a TOML parsing dependency and pin a minimum supported AeroSpace version in the README
- [ ] 1.3 Set up build/run scripts and a basic CI lint/build check

## 2. AeroSpace integration layer

- [ ] 2.1 Implement an AeroSpace CLI client that locates `aerospace` on `PATH` and reports a clear error if missing
- [ ] 2.2 Implement workspace reads: `list-workspaces --all` and `--focused`
- [ ] 2.3 Implement window reads per workspace via `list-windows --workspace <n> --json` and derive distinct owning apps
- [ ] 2.4 Implement monitor reads via `list-monitors --json` and the workspace→monitor mapping
- [ ] 2.5 Implement actions: focus workspace, close all windows in a workspace, move a (specific) workspace to an adjacent monitor
- [ ] 2.6 Resolve and cache application icons for display
- [ ] 2.7 Ensure single-monitor degradation (move = no-op, single outline color) and no background polling

## 3. Configuration

- [ ] 3.1 Define and load `~/.config/gridspaces/gridspaces.toml`; apply built-in defaults when missing
- [ ] 3.2 Parse the 2D grid layout (ordered, possibly ragged rows of workspace names) into a `(row, column)` model
- [ ] 3.3 Parse remappable keybindings with defaults (navigation `hjkl`+arrows, `Enter`, `Esc`, four directional move-to-monitor keys `Shift+hjkl`/`Shift`+arrows)
- [ ] 3.4 Parse behavior toggles (edge wrap; close-all-windows confirmation, default enabled) and expose them to navigation/switching/actions
- [ ] 3.5 Validate configuration, report clear errors, and fall back to defaults per-setting
- [ ] 3.6 Implement `gridspaces reload-config`

## 4. Grid model & layout

- [ ] 4.1 Build the grid model: place configured workspaces by position; compute a single overflow row for ungridded workspaces with windows; hide empty ungridded workspaces
- [ ] 4.2 Implement directional adjacency that skips empty cells and honors the wrap toggle
- [ ] 4.3 Implement the ungridded-focused fallback entry point for directional switching

## 5. Grid overview UI

- [ ] 5.1 Implement the popup window (centered, key-focused), rendering a tile per workspace at its grid position
- [ ] 5.2 Render tiles with app icons, the workspace name/identifier (shortcut reminder), and an empty state
- [ ] 5.3 Render per-monitor outline colors (single color when one monitor)
- [ ] 5.4 Refresh AeroSpace state on open and set the initial highlight to the focused workspace

## 6. In-grid navigation & actions

- [ ] 6.1 Handle navigation keys (move highlight, skip gaps, wrap behavior) without switching workspaces
- [ ] 6.2 Implement confirm (focus highlighted workspace on close) and cancel (close without switching)
- [ ] 6.3 Implement close-all-windows on the highlighted workspace with a default confirmation keypress (toggleable) and tile update
- [ ] 6.4 Implement directional move-to-monitor on the highlighted workspace via `move-workspace-to-monitor --workspace <name> (left|down|up|right)` (no focus change), with a cycle-mode (`next|prev`) alternative and monitor wrap toggle, keeping the grid open and the highlight on the moved workspace, and updating its outline color

## 7. CLI & global integration

- [ ] 7.1 Implement the `gridspaces` CLI: `toggle`/`open`/`close`, `focus --direction <up|down|left|right>`, `reload-config`
- [ ] 7.2 Implement the resident-agent IPC so the CLI signals the agent to show/hide the grid instantly (per the confirmed runtime model)
- [ ] 7.3 Implement headless directional switching (no popup) using the grid topology and wrap setting

## 8. Documentation

- [ ] 8.1 Write README setup: install app + CLI, sample `gridspaces.toml`, recommended keyboard-style workspace naming
- [ ] 8.2 Document the AeroSpace bindings that `exec` the GridSpaces CLI (open-grid + directional switch), with no AeroSpace source changes
- [ ] 8.3 Document permissions, the minimum AeroSpace version, and single-monitor behavior

## 9. Verification

- [ ] 9.1 Verify each spec scenario manually against the implementation (navigation, focus-on-close, cancel, close-all, move-to-monitor, directional switch, overflow, degradation)
- [ ] 9.2 Add automated tests for the grid model (placement, overflow, adjacency, wrap) and config parsing/validation
- [ ] 9.3 Measure idle and on-open resource usage to confirm the lightweight, no-polling goal
