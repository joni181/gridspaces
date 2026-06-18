## Why

[AeroSpace](https://github.com/nikitabobko/AeroSpace) is a fast tiling window manager for macOS, but it has no Mission Control-style overview of its workspaces. There is no way to see, at a glance, which workspaces exist, which apps live in each one, or which monitor a workspace is on. This makes it easy to lose track of windows and slow to move between workspaces spatially.

GridSpaces adds a fast, keyboard-driven visual overview that sits **on top of** AeroSpace (never replacing it), integrating cleanly through AeroSpace's CLI and config so users keep their existing setup and muscle memory.

## What Changes

- Introduce a native macOS app (`Swift` + `SwiftUI`/`AppKit`) that renders a **popup grid overview** of all known AeroSpace workspaces, each tile showing the **app icons** of its open windows.
- Lay workspaces out in a **2D grid** whose positions are defined in a GridSpaces config file, designed to mirror physical keyboard positions (e.g. `1 2 3 4 5` / `Q W E` / `A S D`).
- Surface any workspace that holds windows but is **not** placed in the configured grid in an appended **overflow region**, so no windows are ever hidden.
- Provide **in-grid keyboard navigation** (default `hjkl`, remappable) that moves a **highlight** without switching; closing the grid focuses the highlighted workspace, and `Esc` cancels without switching.
- Provide **in-grid workspace actions**: close all windows in the highlighted workspace, and move the highlighted workspace to an adjacent monitor (directional). Each tile shows a **per-monitor colored outline**.
- Provide **global directional workspace switching** outside the grid: a headless, popup-free 2D switch (up/down/left/right) of the focused workspace, like macOS `Ctrl+Arrow` but in two dimensions.
- Read AeroSpace state on demand via its CLI (`list-workspaces`, `list-windows --json`, `list-monitors`) — **no polling**, refresh only when the grid opens or a command runs.
- Wire all global shortcuts through **AeroSpace config bindings** that `exec` a GridSpaces CLI command, requiring **no changes to AeroSpace source** and **no native global hotkey registration** by GridSpaces.
- Provide a **TOML configuration dotfile** (mirroring AeroSpace's style) for grid layout, keybindings, and behavior toggles.
- Gracefully **degrade to single-monitor** behavior (move-to-monitor becomes a no-op, single outline color) when only one display is present.

Out of scope for this change (future work): live window thumbnails (currently app icons only), an option to hide empty workspaces, a background daemon with event-driven state, and auto-deriving grid positions from keyboard geometry.

## Capabilities

### New Capabilities

- `aerospace-integration`: Reading workspace/window/monitor state from the AeroSpace CLI and executing AeroSpace actions on GridSpaces' behalf, including required AeroSpace config additions and single-monitor degradation.
- `workspace-grid-overview`: The popup grid window — layout rules (configured grid, overflow region, ragged rows/empty cells), tile rendering with app icons, per-monitor outline colors, and open behavior.
- `grid-navigation`: In-grid keyboard navigation and selection — highlight movement (default `hjkl`), edge-wrap behavior, focus-the-highlight on close, and `Esc` to cancel.
- `workspace-actions`: Operations invoked on the highlighted workspace from within the grid — close all windows, and move the workspace to an adjacent monitor directionally.
- `global-directional-switching`: Headless (popup-free) 2D directional switching of the focused workspace, driven by AeroSpace bindings.
- `configuration`: The GridSpaces TOML dotfile — grid layout, remappable keybindings, and behavior toggles, plus discovery/reload semantics.

### Modified Capabilities

<!-- None. This is the foundational change; no existing GridSpaces specs exist yet. -->

## Impact

- **New codebase**: native macOS app + bundled `gridspaces` CLI (Swift). Greenfield repo (currently only `README.md`).
- **AeroSpace config**: users add binding(s) that `exec` the GridSpaces CLI, and (recommended) keep `persistent-workspaces` matching their configured grid. Documented as setup steps in the README.
- **New config file**: `~/.config/gridspaces/gridspaces.toml`.
- **Permissions/dependencies**: AeroSpace must be installed and on `PATH`. No Screen Recording permission required (app icons only). Process/runtime model (resident agent vs. cold launch) and the exact CLI command surface are defined in `design.md`.
- **README**: must document end-to-end setup (config file, AeroSpace bindings, recommended keyboard-style workspace naming).
