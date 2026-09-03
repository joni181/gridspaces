## Why

Workspace tile colors show which monitor a workspace belongs to, but they do not show which physical display each color represents. A compact monitor-layout panel can map those colors directly onto the user's real display arrangement while the grid is open.

## What Changes

- Add a configurable monitor-layout panel shown to the left of the main workspace grid when the grid opens.
- Render a scaled representation of the connected monitors that preserves relative physical position, relative size, and aspect ratio.
- Color each monitor representation with the same active monitor palette used by workspace tile outlines.
- Mark the monitor containing the highlighted workspace as active. Mouse hover SHALL NOT affect the active monitor.
- Hide the panel when the connected monitor count is below a configurable minimum, defaulting to 2 monitors.
- Allow users to disable the panel entirely through `[appearance]`, matching the existing tree-panel configuration style.
- Update configuration examples and documentation for the new appearance keys.

## Capabilities

### New Capabilities

- `monitor-layout-panel`: Defines the panel lifecycle, physical monitor layout rendering, color assignment, and active monitor behavior.

### Modified Capabilities

- `configuration`: Add appearance settings for enabling the monitor-layout panel and setting the minimum connected monitor count required to show it.

## Impact

- `Sources/GridSpacesCore/Configuration.swift` — appearance model, TOML decoding, defaults, and validation.
- New or related SwiftUI views — render the monitor-layout companion panel in the same visual style as the tree panel.
- `Sources/GridSpacesAgent/GridViewModel.swift` — expose monitor colors and active monitor derivation for the highlighted workspace.
- `Sources/GridSpacesAgent/PanelController.swift` — create, show, hide, size, and position the monitor-layout companion panel so it stays left of the main panel and coexists with the tree panel.
- Monitor-to-screen geometry logic — derive relative display rectangles from the current macOS screen arrangement while preserving AeroSpace monitor color assignment.
- Core and agent tests — configuration defaults/validation, panel visibility thresholds, geometry scaling, palette reuse, active-state behavior, and tree-panel coexistence.
- `config/gridspaces.toml` and `docs/configuration.md` — example and reference documentation.
