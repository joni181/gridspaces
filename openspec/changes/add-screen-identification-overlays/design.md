## Context

GridSpaces already assigns workspace tile outline colors from `appearance.monitor_colors` using each monitor's position in AeroSpace's reported monitor list. This communicates that tiles belong to different monitors, but it does not visually associate a palette color with a physical display.

The popup is managed by `PanelController` as a floating `NSPanel`. The new visual treatment must span every connected `NSScreen`, follow the popup lifecycle, preserve keyboard focus on the grid, and never intercept pointer input.

## Goals / Non-Goals

**Goals:**

- Show the active palette color on the corresponding physical screen while the grid is open.
- Let users configure whether borders are shown and their width.
- Let users suppress screen identification until a configurable number of monitors are connected.
- Preserve the existing workspace tile color behavior.
- Keep all overlay windows non-activating and input-transparent.
- Handle display changes and configuration reloads without leaving stale overlays behind.
- Keep borders visible when macOS reserves menu-bar space on any display.
- Keep overlay setup and refresh work out of the grid popup process.
- Present overlays without waiting for the full workspace and window snapshot.

**Non-Goals:**

- Screen infill or other full-screen translucent coloring.
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
```

The defaults are enabled borders, a width of 5 logical pixels, and a minimum of 2 connected monitors.

Flat keys keep the existing `[appearance]` table compact and avoid introducing a nested table for three closely related scalar settings.

### Decision: Apply the minimum monitor count to the complete overlay

`screen_minimum_monitors` controls the minimum number of currently connected monitors required before GridSpaces shows screen-identification borders. It accepts positive integers and defaults to 2.

### Decision: Reuse the monitor palette and monitor-order assignment

Each screen overlay will use the color at the corresponding monitor's index in AeroSpace's reported monitor list, including the existing palette-cycling behavior. The physical screen and all workspace tiles assigned to it must therefore share a color.

The implementation will reconcile AeroSpace monitor information with the current `NSScreen` snapshot. Matching should use stable display metadata where available and deterministic ordering as a fallback. This mapping will be isolated and tested because AppKit screen order alone is not the public color-assignment contract.

### Decision: Render border-only mode with narrow opaque edge windows

GridSpaces will use four narrow opaque windows per screen, one for each edge, rather than a full-screen transparent window. This limits backing-store and compositor work to the visible border pixels. The windows ignore mouse events, cannot become key or main, join all Spaces, and remain below the interactive popup.

Screen infill is deferred. Measurements showed that a display-sized translucent surface caused unacceptable compositor CPU and memory usage even when application code itself was idle.

### Decision: Derive the top border from each screen's current visible frame

Each overlay window will continue to cover the screen's full frame, but its top border position will account for the difference between `NSScreen.frame.maxY` and `NSScreen.visibleFrame.maxY`. A positive difference represents system-reserved space at the top of that specific display, such as a menu bar. Screens without a top reservation receive no inset.

Only the top edge uses this calculation. Dock insets on the sides or bottom do not move the corresponding screen border.

### Decision: Couple overlay lifetime to popup visibility

The grid agent will send show and hide commands to a persistent overlay helper process. Every popup-close path will request removal of all overlay windows, including cancel, workspace selection, focus loss, and application-driven closure.

Reloading configuration while the popup is open will rebuild or update the overlays from the new settings. Opening the popup again will take a fresh `NSScreen` snapshot so display additions, removals, and rearrangements do not reuse stale geometry.

### Decision: Run overlay windows in a persistent helper process

The application bundle will include a background-only `GridSpacesOverlayAgent` executable. The main grid agent starts it once and communicates through local IPC. Overlay window creation, drawing, and monitor refresh therefore use a separate main thread and cannot block grid popup presentation.

The helper remains alive with the grid agent to avoid process-launch cost on each open. Agent shutdown requests helper shutdown, and build/install packaging includes both executables.

### Decision: Cache monitor ordering and refresh only monitors

The overlay helper keeps the most recently successful AeroSpace monitor list in memory. A show command immediately renders from that cache and the current `NSScreen` geometry. If no cache exists yet, deterministic current-screen order provides the initial palette assignment.

After showing, the helper runs only `aerospace list-monitors --json` in the background. If the result changes, it updates visible overlays. It does not wait for or invoke the full workspace snapshot, whose serialized per-workspace window queries are the dominant source of the previous delay.

### Decision: Validate each new setting independently

`screen_border_width` and `screen_minimum_monitors` must be positive integers. An invalid value produces a clear configuration warning and falls back only that field to its built-in default. Valid sibling settings remain active.

Boolean values continue to use TOML's native boolean decoding. A type mismatch that prevents decoding follows the existing configuration error behavior.

## Risks / Trade-offs

- [Full-screen transparent windows cause high compositor CPU and memory usage] → Do not ship infill; render borders with narrow opaque edge windows only.
- [The overlay is unnecessary in a single-monitor setup] → Default the minimum monitor count to 2 while allowing users to select 1 for always-on behavior.
- [AeroSpace and AppKit may identify or order displays differently] → Isolate monitor-to-screen reconciliation, prefer matching display metadata, and cover fallback behavior with tests.
- [Overlays could interfere with normal input or popup activation] → Use non-activating windows that ignore mouse events and cannot become key or main.
- [Display topology can change while the popup is open] → Reconcile screens on each open; live topology tracking during one popup session is deferred unless AppKit notifications make it necessary for safe cleanup.
- [The first show has no cached AeroSpace ordering] → Render immediately in deterministic screen order, then correct the assignment after the monitor-only refresh.
- [The helper is not ready when the first show command is sent] → Start it with the main agent and retry IPC asynchronously without blocking popup presentation.

## Migration Plan

No migration is required. Existing configurations omit the new keys and receive enabled 5-pixel borders when at least 2 monitors are connected. Users who want overlays with one monitor can set `appearance.screen_minimum_monitors = 1`. Users who want the previous behavior can set `appearance.screen_borders = false`.

Rollback removes the overlay windows and new settings. Existing TOML files remain decodable because unknown keys are ignored by the current decoder.

## Open Questions

None.
