## Context

GridSpaces already assigns workspace tile outline colors from `appearance.monitor_colors` using each monitor's position in AeroSpace's reported monitor list. This communicates that tiles belong to different monitors, but it does not visually associate a palette color with a physical display.

The popup is managed by `PanelController` as a floating `NSPanel`. The new visual treatment must span every connected `NSScreen`, follow the popup lifecycle, preserve keyboard focus on the grid, and never intercept pointer input.

## Goals / Non-Goals

**Goals:**

- Show the active palette color on the corresponding physical screen while the grid is open.
- Let users configure whether borders are shown and their width.
- Let users suppress screen identification until a configurable number of monitors are connected.
- Support an independently enabled same-color infill with configurable transparency.
- Preserve the existing workspace tile color behavior.
- Keep all overlay windows non-activating and input-transparent.
- Handle display changes and configuration reloads without leaving stale overlays behind.

**Non-Goals:**

- Configuring separate colors for tiles, borders, and infill.
- Persistently showing screen overlays while the workspace grid is closed.
- Drawing monitor names, numbers, labels, or other content on the screens.
- Adding per-monitor border widths, fill settings, or colors.
- Changing AeroSpace's monitor discovery or ordering.

## Decisions

### Decision: Add flat screen-overlay settings under `[appearance]`

The TOML form will be:

```toml
[appearance]
monitor_colors = ["#32ADE6", "#FF9500", "#34C759", "#FF2D55", "#AF52DE", "#FFCC00"]
screen_borders = true
screen_border_width = 5
screen_minimum_monitors = 2
screen_infill = false
screen_infill_transparency = 80
```

The defaults are enabled borders, a width of 5 logical pixels, a minimum of 2 connected monitors, disabled infill, and 80 percent infill transparency. The transparency default is dormant while infill is disabled.

Flat keys keep the existing `[appearance]` table compact and avoid introducing a nested table for five closely related scalar settings.

### Decision: Apply the minimum monitor count to the complete overlay

`screen_minimum_monitors` controls the minimum number of currently connected monitors required before GridSpaces shows any screen-identification overlay. It accepts positive integers and defaults to 2. When the connected monitor count is below the configured minimum, neither borders nor infill are shown.

Applying the threshold to the complete overlay matches the purpose of avoiding unnecessary screen coloring in simple display setups. Applying it only to borders could still tint a single-monitor setup when infill is enabled.

### Decision: Keep an explicit infill toggle

`screen_infill` controls whether GridSpaces draws a fill. `screen_infill_transparency` controls the strength of that fill only when enabled. Transparency accepts integers from 0 through 100 inclusive: 0 is fully opaque, while 100 is fully transparent.

Although 100 percent transparency is visually equivalent to disabled infill, the explicit toggle separates user intent from visual strength, provides a clear default of "no infill," and allows a preferred transparency to remain configured while infill is toggled.

### Decision: Reuse the monitor palette and monitor-order assignment

Each screen overlay will use the color at the corresponding monitor's index in AeroSpace's reported monitor list, including the existing palette-cycling behavior. The physical screen and all workspace tiles assigned to it must therefore share a color.

The implementation will reconcile AeroSpace monitor information with the current `NSScreen` snapshot. Matching should use stable display metadata where available and deterministic ordering as a fallback. This mapping will be isolated and tested because AppKit screen order alone is not the public color-assignment contract.

### Decision: Use one transparent, non-activating overlay window per screen

While the grid is open, the connected monitor count meets the configured minimum, and either the border or infill has a visible effect, GridSpaces will maintain one borderless overlay window for each connected screen. Each window will:

- cover the screen's full frame;
- render the configured border inward so its complete width remains on-screen;
- optionally fill the enclosed screen area with the same color;
- ignore mouse events and refuse key/main-window status;
- join all Spaces and remain available beside full-screen applications;
- stay visually below the interactive GridSpaces popup.

Separate windows follow macOS display geometry directly, including negative global coordinates and displays with different resolutions.

### Decision: Couple overlay lifetime to popup visibility

Overlays will be presented only after the grid refresh provides the current monitor list, immediately before the popup is shown. Every popup-close path will remove all overlay windows, including cancel, workspace selection, focus loss, and application-driven closure.

Reloading configuration while the popup is open will rebuild or update the overlays from the new settings. Opening the popup again will take a fresh `NSScreen` snapshot so display additions, removals, and rearrangements do not reuse stale geometry.

### Decision: Validate each new setting independently

`screen_border_width` and `screen_minimum_monitors` must be positive integers. `screen_infill_transparency` must be an integer in the inclusive range 0 through 100. An invalid value produces a clear configuration warning and falls back only that field to its built-in default. Valid sibling settings remain active.

Boolean values continue to use TOML's native boolean decoding. A type mismatch that prevents decoding follows the existing configuration error behavior.

## Risks / Trade-offs

- [A strong infill can obscure content on every display] → Keep infill disabled by default and expose transparency with a conservative 80 percent default.
- [The overlay is unnecessary in a single-monitor setup] → Default the minimum monitor count to 2 while allowing users to select 1 for always-on behavior.
- [A 100 percent transparent infill creates windows with no visible fill] → Treat it as valid so the transparency scale remains complete; avoid creating overlays only when neither border nor fill can be seen.
- [AeroSpace and AppKit may identify or order displays differently] → Isolate monitor-to-screen reconciliation, prefer matching display metadata, and cover fallback behavior with tests.
- [Overlays could interfere with normal input or popup activation] → Use non-activating windows that ignore mouse events and cannot become key or main.
- [Display topology can change while the popup is open] → Reconcile screens on each open; live topology tracking during one popup session is deferred unless AppKit notifications make it necessary for safe cleanup.

## Migration Plan

No migration is required. Existing configurations omit the new keys and receive enabled 5-pixel borders when at least 2 monitors are connected, with no infill. Users who want overlays with one monitor can set `appearance.screen_minimum_monitors = 1`. Users who want the previous behavior can set `appearance.screen_borders = false`; with infill also disabled, no screen overlays are shown.

Rollback removes the overlay windows and new settings. Existing TOML files remain decodable because unknown keys are ignored by the current decoder.

## Open Questions

None.
