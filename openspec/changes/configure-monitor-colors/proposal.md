## Why

Monitor outline colors are currently hard-coded, so users cannot adapt them for personal preference, accessibility, or visual contrast with their desktop. GridSpaces should expose the palette in its TOML configuration while preserving the current appearance for users who do not configure it.

## What Changes

- Add an optional `monitor_colors` setting under a new `[appearance]` configuration table.
- Accept monitor colors as an ordered array of `#RRGGBB` hex strings.
- Preserve the current cyan, orange, green, pink, purple, and yellow palette as the built-in default.
- Assign colors to monitors in AeroSpace's reported monitor order and cycle through the configured palette when there are more monitors than colors.
- Validate configured color values and fall back to the complete default palette when the setting is empty or invalid.
- Document the setting, syntax, defaults, monitor ordering, and fallback behavior in `docs/configuration.md`.

## Capabilities

### New Capabilities

<!-- None. -->

### Modified Capabilities

- `configuration`: Add the optional appearance palette, its defaults, validation behavior, and configuration documentation.
- `workspace-grid-overview`: Render monitor outlines using the configured palette rather than a hard-coded palette.

## Impact

- `Sources/GridSpacesCore/Configuration.swift` — configuration model, TOML decoding, defaults, and validation.
- `Sources/GridSpacesAgent/GridViewModel.swift` — convert configured hex values to SwiftUI colors and select colors by monitor order.
- `Tests/GridSpacesCoreTests/ConfigurationTests.swift` and agent/view-model tests — default, custom, invalid, and palette-cycling coverage.
- `config/gridspaces.toml` and `docs/configuration.md` — example and reference documentation.
