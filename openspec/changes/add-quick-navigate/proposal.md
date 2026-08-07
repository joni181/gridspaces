## Why

Switching to an adjacent workspace through the grid costs three deliberate steps: open the grid, move the highlight, confirm. The popup-free alternative, `gridspaces focus --direction <d>`, avoided those steps but was so slow (5 + N AeroSpace subprocess spawns per keypress, 1–2 seconds observed) that it was unusable and had already been commented out of the maintainer's AeroSpace config.

A single held shortcut can do both jobs: show the grid with the highlight already on the neighbouring workspace, let the user keep stepping while the modifiers stay down, and commit the switch the moment they let go.

## What Changes

- Add a `quick-navigate <left|down|up|right>` command that opens the grid with the highlight already moved one tile in the requested direction.
- While the trigger modifiers stay held, further presses of the quick-navigate hotkeys — or of the ordinary navigation keys and arrows with those modifiers held — keep moving the highlight.
- Releasing any of the trigger modifiers closes the grid and focuses the highlighted workspace. No separate confirm keypress.
- Declare the shortcut in `[keys]` as `quick-navigate <direction>`, defaulting to `ctrl-alt-shift-h/j/k/l`. AeroSpace still owns the global binding; the GridSpaces entry tells the grid which modifiers to watch for release.
- Derive the destination from the configured grid geometry as soon as the focused workspace is known, so the highlight is correct before the full workspace snapshot arrives.
- **BREAKING**: Remove `gridspaces focus --direction <d>` and the `global-directional-switching` capability. Quick-navigate covers the same intent on the same keys and is agent-resident rather than spawning a snapshot per keypress.

## Capabilities

### New Capabilities

- `quick-navigate`: Held-modifier directional workspace switching — grid opens pre-highlighted, stays navigable while held, commits on release.

### Modified Capabilities

- `configuration`: Add the `quick-navigate <direction>` command values, their `ctrl-alt-shift-h/j/k/l` defaults, and a warning when a quick-navigate hotkey carries no modifier.

### Removed Capabilities

- `global-directional-switching`: Superseded by `quick-navigate`.

## Impact

- `Sources/GridSpacesCore/Configuration.swift` — quick-navigate bindings, command mapping, modifier lookup, modifier-less warning.
- `Sources/GridSpacesCore/Models.swift` — public hotkey component parsing.
- `Sources/GridSpacesCore/IPC.swift` — four quick-navigate agent commands.
- `Sources/GridSpacesAgent/PanelController.swift` — pre-highlighted open, modifier-release watch, held-modifier navigation, commit/disarm.
- `Sources/GridSpacesAgent/GridViewModel.swift` — quick-navigate destination resolution and highlight preservation across the snapshot.
- `Sources/gridspaces/main.swift` — new `quick-navigate` command; `focus` removed.
- Sample config, README, configuration reference, verification checklist, tests.
- The pending `optimize-directional-switching` change targets the removed command and is dropped by this change. The pending `config-validation-errors` change still uses `focus --direction` as its example CLI invocation and needs a different example before it is applied.
