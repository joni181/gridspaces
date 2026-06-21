## Why

Workspace tile colors identify a workspace's monitor, but with three or more displays it is not immediately obvious which physical screen corresponds to each color. Showing the same color around each screen while the grid is open makes that relationship visible without requiring users to memorize monitor ordering.

## What Changes

- Add a configurable identification overlay around every connected screen while the workspace grid is open.
- Reuse the active `appearance.monitor_colors` palette so each screen overlay matches the workspace tile outline color for that monitor.
- Add `[appearance]` settings to enable or disable screen borders, set their width, and require a configurable minimum number of connected monitors.
- Default to enabled 5-pixel borders shown when at least 2 monitors are connected.
- Keep overlays non-interactive and remove them whenever the grid closes.
- Render overlays in a persistent helper process so overlay creation and monitor refresh cannot delay the grid popup.
- Show overlays immediately from cached monitor ordering, then refresh monitor state independently from the full workspace snapshot.
- Validate border width and minimum monitor count, falling back to the affected setting's default when invalid.
- Document the settings, defaults, units, and transparency semantics in `docs/configuration.md`.

## Capabilities

### New Capabilities

- `screen-identification-overlay`: Defines the lifecycle, color assignment, border rendering, performance, and interaction behavior of the per-screen overlays.

### Modified Capabilities

- `configuration`: Add appearance settings and validation rules for screen identification borders and minimum monitor count.

## Impact

- `Sources/GridSpacesCore/Configuration.swift` — appearance model, TOML decoding, defaults, and validation.
- `Sources/GridSpacesAgent/PanelController.swift`, a persistent overlay helper executable, and shared IPC — independently show, update, and remove one non-interactive overlay per connected screen.
- Monitor-to-screen matching logic — ensure physical screen overlays use the same palette positions as workspace tiles.
- Core and agent tests — configuration defaults and validation, overlay presentation state, geometry, colors, and cleanup.
- `config/gridspaces.toml` and `docs/configuration.md` — example and reference documentation.
