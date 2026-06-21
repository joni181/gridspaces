## Why

Workspace tile colors identify a workspace's monitor, but with three or more displays it is not immediately obvious which physical screen corresponds to each color. Showing the same color around each screen while the grid is open makes that relationship visible without requiring users to memorize monitor ordering.

## What Changes

- Add a configurable identification overlay around every connected screen while the workspace grid is open.
- Reuse the active `appearance.monitor_colors` palette so each screen overlay matches the workspace tile outline color for that monitor.
- Add `[appearance]` settings to enable or disable screen borders, set their width, require a configurable minimum number of connected monitors, enable an optional same-color infill, and set infill transparency.
- Default to enabled 5-pixel borders shown when at least 2 monitors are connected, with infill disabled.
- Keep overlays non-interactive and remove them whenever the grid closes.
- Validate border width, minimum monitor count, and infill transparency, falling back to the affected setting's default when invalid.
- Document the settings, defaults, units, and transparency semantics in `docs/configuration.md`.

## Capabilities

### New Capabilities

- `screen-identification-overlay`: Defines the lifecycle, color assignment, border, optional infill, and interaction behavior of the per-screen overlays.

### Modified Capabilities

- `configuration`: Add appearance settings and validation rules for screen identification borders, minimum monitor count, and infill.

## Impact

- `Sources/GridSpacesCore/Configuration.swift` — appearance model, TOML decoding, defaults, and validation.
- `Sources/GridSpacesAgent/PanelController.swift` and new or related AppKit UI types — create, update, and remove one non-interactive overlay per connected screen.
- Monitor-to-screen matching logic — ensure physical screen overlays use the same palette positions as workspace tiles.
- Core and agent tests — configuration defaults and validation, overlay presentation state, geometry, colors, and cleanup.
- `config/gridspaces.toml` and `docs/configuration.md` — example and reference documentation.
