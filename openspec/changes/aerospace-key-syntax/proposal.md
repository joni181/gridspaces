## Why

Gridspaces is built on top of AeroSpace and should feel like a natural extension of it. The current `[keys]` config syntax inverts AeroSpace's convention — gridspaces writes `command = "hotkey"` with `+` as the modifier separator, while AeroSpace writes `hotkey-combo = 'command'` with `-`. Users who already configure AeroSpace will find the inconsistency jarring and error-prone.

## What Changes

- **BREAKING**: The `[keys]` section is restructured so that the TOML key is the hotkey combination and the value is the command name (flipping the current direction).
- **BREAKING**: Modifier separator changes from `+` to `-` (e.g., `shift+h` → `shift-h`), matching AeroSpace exactly.
- **BREAKING**: The `[keys.workspaces]` subtable retains the `hotkey = 'workspace-name'` direction (already correct) but any multi-key values that used `+` must now use `-`.
- The config parser (`ConfigLoader`) is updated to decode the new table shape and validate hotkey strings using `-`-separated tokens.
- Built-in defaults and the bundled example config (`config/gridspaces.toml`) are updated to the new syntax.
- ConfigurationTests are updated to exercise the new format.

## Capabilities

### New Capabilities

- `aerospace-key-syntax`: The `[keys]` config section now uses `hotkey-combo = 'command'` syntax with `-` as the modifier separator, matching AeroSpace's binding syntax.

### Modified Capabilities

<!-- none — no existing specs to delta against -->

## Impact

- `Sources/GridSpacesCore/Configuration.swift` — `PartialKeyBindings`, `KeyBindings`, and the `merge` parsing logic must be restructured.
- `config/gridspaces.toml` — example config must be rewritten.
- `Tests/GridSpacesCoreTests/ConfigurationTests.swift` — all key-related test fixtures must be updated.
- Any users with existing `~/.config/gridspaces/gridspaces.toml` files will need to migrate their `[keys]` section manually (migration note should appear in the changelog).
