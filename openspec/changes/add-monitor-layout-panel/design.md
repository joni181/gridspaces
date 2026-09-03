## Context

GridSpaces already assigns workspace tile outline colors from `appearance.monitor_colors` using AeroSpace's reported monitor order. The main popup is a SwiftUI `GridView` hosted in one `NSPanel`; the optional tree panel is a separate companion `NSPanel` controlled by `appearance.show_tree_panel`.

The requested monitor-layout panel should follow that companion-panel model. It is a compact map beside the workspace grid, not a persistent overlay drawn onto physical screens. The stale screen-identification overlay change artifacts are removed as part of this cleanup.

## Goals / Non-Goals

**Goals:**

- Show a compact representation of the connected physical monitor arrangement beside the workspace grid.
- Preserve each monitor's aspect ratio, relative size, and relative position.
- Reuse the exact monitor colors already used for workspace tile outlines.
- Light up the monitor that owns the highlighted workspace.
- Let users disable the panel and configure whether it appears for one-monitor setups.
- Keep the existing tree panel usable when both panels are enabled.
- Avoid background polling; derive the panel from the same fresh state used when the grid opens.

**Non-Goals:**

- Moving workspaces by clicking or dragging monitor shapes.
- Configuring separate colors for the monitor-layout panel.
- Showing persistent monitor names, numbers, resolutions, or labels inside the compact map.
- Creating screen-identification overlays or other full-screen display treatments.
- Changing active monitor state in response to mouse hover.
- Live display-topology tracking while the grid is closed.

## Decisions

### Decision: Add flat appearance settings for panel visibility and threshold

The TOML form will be:

```toml
[appearance]
show_monitor_layout_panel = true
monitor_layout_minimum_monitors = 2
```

`show_monitor_layout_panel` disables the feature when `false`. `monitor_layout_minimum_monitors` is a positive integer threshold and defaults to 2, so the panel is shown by default for multi-monitor setups and hidden by default for one-monitor setups. Setting it to 1 opts into the panel with one monitor.

Alternative considered: a dedicated `show_monitor_layout_panel_with_one_monitor` boolean. A threshold is more general and avoids adding a second single-purpose toggle.

### Decision: Implement the monitor layout as a tree-style companion panel

The monitor-layout panel will be a separate non-activating `NSPanel`, matching the tree panel approach. It will be positioned to the left of the main grid panel, use the same gap from the main panel, stay vertically centered against the main panel, and use the same overall material/background style.

When both the monitor-layout panel and tree panel are enabled, the monitor-layout panel owns the left side of the main panel. The tree panel should keep its existing companion behavior while avoiding overlap; in practice it should prefer the right side when the monitor-layout panel is visible.

Alternative considered: embed the monitor layout as a left rail inside `GridView`. That would avoid an additional window, but it would diverge from the tree panel pattern and make the main popup wider in the common multi-monitor case.

### Decision: Derive geometry from `NSScreen` frames and colors from AeroSpace monitor order

The layout view will use the current `NSScreen.screens` frame data to compute physical arrangement. It will normalize the union of all screen frames, apply one uniform scale to fit the available panel drawing area, and flip the Y axis for SwiftUI drawing. This preserves aspect ratio, relative size, and relative position, including displays above, below, or left of the primary display.

Color assignment remains based on AeroSpace monitor order, because that is the existing contract for workspace tile colors. The implementation should isolate reconciliation between AeroSpace monitors and `NSScreen` values. It should prefer stable display metadata when available and fall back to deterministic ordering when exact matching is not possible. Reconciliation must be one-to-one: a single AeroSpace monitor must not be assigned to multiple physical screen shapes.

Alternative considered: use AeroSpace monitor order alone and render equal-size rectangles in a row. That would preserve color order but fail the physical-layout requirement.

### Decision: The highlighted workspace is the only active source

The highlighted workspace drives the active monitor state. Keyboard navigation, quick-navigate, initial focus, and workspace movement update the panel by moving the highlight. Mouse hover does not affect which monitor lights up.

The active monitor should have a visibly stronger fill, border, glow, or brightness. Inactive monitors should still retain their assigned colors but be visually subdued enough that the active state is clear. Adjacent monitor shapes should have a small visual gap so their colors and active states remain distinct. Reduce Motion should not be required for the active state to be understandable.

Alternative considered: hover activation. That is a common pointer UI pattern, but GridSpaces is keyboard-first and the keyboard-controlled highlight is the user's actual cursor in this interface.

### Decision: Keep the panel compact and non-interactive

The panel is visual context, not a control surface. It will not change focus, accept clicks, add monitor-specific actions, or respond to hover for active-state changes. The shapes may expose accessibility labels or help text, but the compact map should not depend on visible labels to be useful.

Alternative considered: clickable monitor targets for moving the highlighted workspace. That expands the feature into a new workspace action and should be specified separately if desired.

### Decision: Update the panel on refresh and configuration reload

The panel is recomputed when the grid opens, after workspace and monitor state is refreshed. If the user reloads configuration while the popup is open, the visibility toggle, threshold, palette, and active color mapping update with the refreshed view model state. Closing the grid removes the panel with the main popup.

This matches the current on-demand state model and avoids continuous monitoring while the app is idle.

## Risks / Trade-offs

- [AeroSpace and AppKit may expose monitors in different identifiers or orders] -> Isolate reconciliation, prefer stable metadata, and test deterministic fallback behavior.
- [The default adds a companion panel for multi-monitor users] -> Keep the panel compact and provide `show_monitor_layout_panel = false`.
- [Very asymmetric monitor setups can produce tiny shapes] -> Preserve geometry first, with clear active styling and accessibility/help text for inspectability.
- [Several active OpenSpec changes touch `[appearance]`] -> Merge configuration fields carefully and keep validation independent per setting.

## Migration Plan

No migration is required. Existing configurations omit the new keys and receive the new default behavior: the monitor-layout panel appears when at least two monitors are connected. Users who want the previous behavior can set `appearance.show_monitor_layout_panel = false`; users who want the panel with one monitor can set `appearance.monitor_layout_minimum_monitors = 1`.

Rollback removes the view and new settings. Existing TOML files containing the new keys remain decodable by older versions only if unknown appearance keys are ignored by the decoder; otherwise users can remove the two keys.

## Open Questions

None.
