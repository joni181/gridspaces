## Why

GridSpaces currently lets users move a highlight or send a workspace to another display, but it cannot change which configured workspace name/number owns a group of windows. Users need an in-grid way to move a workspace's contents through the configured topology without rebuilding the workspace manually.

## What Changes

- Add configurable in-grid actions that move the highlighted workspace's window set left, down, up, or right through the configured grid.
- Exchange the source and destination window sets when the destination is occupied; moving toward an empty workspace transfers the source windows and leaves the source empty.
- Keep the highlight attached to the moved source contents by advancing it to the destination tile after a successful operation.
- Use AeroSpace's window-ID-targeted `move-node-to-workspace` command. Preserve the membership of each window set, while treating exact tiling-tree preservation as best-effort because AeroSpace exposes no public workspace rename or whole-tree move operation.
- Add default bindings `Alt+h/j/k/l` for workspace-content movement.
- **BREAKING**: Replace the ambiguous display movement commands `move-left/right/up/down/next/previous` with argument-style `move-to-display <left|down|up|right|next|previous>`. The old command names will no longer be accepted.
- Add an iOS-style shake hint while the common workspace-movement modifier set is held. The hint is enabled only when all four configured directional bindings share the same non-empty modifier set and the held modifiers match it exactly.
- Keep merging two occupied workspaces, drag-and-drop movement, and exact layout-tree reconstruction out of scope.

## Capabilities

### New Capabilities

- `workspace-reordering`: Directional movement and swapping of complete workspace window sets, highlight behavior, failure handling, and the conditional move-mode visual hint.

### Modified Capabilities

- `configuration`: Add workspace-reordering defaults and replace the old display-movement command names with argument-style action names.
- `workspace-actions`: Rename the canonical in-grid actions that move a workspace between displays so they are distinct from workspace-content movement.

## Impact

- `GridModel` needs directional destination resolution suitable for a mutating action.
- `AeroSpaceClient` needs a multi-window exchange operation built on `list-windows` and `move-node-to-workspace --window-id`.
- `GridViewModel`, `PanelController`, and `GridView` need action dispatch, exact modifier-state tracking, refresh/highlight handling, busy-state protection, and shake animation.
- Configuration parsing, sample config, documentation, and tests need new action names and defaults.
- Requires an AeroSpace version whose `move-node-to-workspace` command supports `--window-id`; the currently verified local version is 0.20.3-Beta.
