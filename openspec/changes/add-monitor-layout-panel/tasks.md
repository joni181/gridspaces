## 1. Configuration model and validation

- [x] 1.1 Add `showMonitorLayoutPanel` and `monitorLayoutMinimumMonitors` to `Appearance` with defaults `true` and `2`
- [x] 1.2 Decode `appearance.show_monitor_layout_panel` and `appearance.monitor_layout_minimum_monitors`
- [x] 1.3 Validate `monitor_layout_minimum_monitors` as a positive integer, warn on invalid values, and fall back only that field to `2`
- [x] 1.4 Add configuration tests for omitted values, disabled panel, one-monitor opt-in, larger thresholds, and invalid thresholds

## 2. Monitor geometry and color mapping

- [x] 2.1 Add a small monitor-layout model that stores each rendered monitor rectangle, monitor ID when known, name when known, color hex, and active state
- [x] 2.2 Derive monitor rectangles from `NSScreen` frames using one uniform scale over the union of connected screen frames
- [x] 2.3 Reconcile AeroSpace monitor order with `NSScreen` data, preferring stable display metadata and using deterministic fallback ordering when exact matching is unavailable
- [x] 2.4 Reuse the existing monitor palette and cycling logic so monitor shapes match workspace tile outline colors
- [x] 2.5 Add tests for side-by-side geometry, vertical offsets, different monitor sizes, palette cycling, and fallback matching
- [x] 2.6 Add regression coverage that prevents one AeroSpace monitor from being assigned to multiple physical screen shapes

## 3. Highlight and active monitor state

- [x] 3.1 Derive the active monitor from the highlighted workspace only
- [x] 3.2 Update the active monitor when keyboard navigation, quick-navigate, or workspace actions change the highlight
- [x] 3.3 Ensure mouse hover over workspace tiles does not affect active monitor state
- [x] 3.4 Add tests for highlighted-workspace activation, keyboard navigation updates, hover non-effects, and unknown monitor assignments

## 4. Companion panel rendering and lifecycle

- [x] 4.1 Add a compact `MonitorLayoutPanel` SwiftUI view hosted in a separate non-activating companion `NSPanel`
- [x] 4.2 Conditionally show the companion panel only when enabled and the connected monitor count meets `monitorLayoutMinimumMonitors`
- [x] 4.3 Render inactive monitors with subdued assigned color and active monitors with a visibly brighter fill, border, glow, or equivalent emphasis
- [x] 4.4 Position the monitor-layout panel left of the main panel using the same gap and vertical centering behavior as the tree panel
- [x] 4.5 Preserve keyboard handling and ensure clicks or hover in the monitor layout do not trigger workspace actions
- [x] 4.6 Ensure the monitor-layout panel and existing tree panel can both be visible without overlapping the main grid or each other
- [x] 4.7 Add accessibility labels or help text for monitor shapes without depending on visible labels in the compact map
- [x] 4.8 Add a small visual gap between adjacent monitor shapes

## 5. Documentation and examples

- [x] 5.1 Add the new default appearance keys to `config/gridspaces.toml`
- [x] 5.2 Document `show_monitor_layout_panel`, `monitor_layout_minimum_monitors`, defaults, one-monitor opt-in, validation behavior, and palette reuse in `docs/configuration.md`
- [x] 5.3 Ensure documentation does not reference stale screen-identification overlay settings

## 6. Verification

- [x] 6.1 Run the Swift test suite and resolve regressions
- [ ] 6.2 Manually verify the default shows the panel with 2 or more monitors and hides it with 1 monitor
- [ ] 6.3 Manually verify `show_monitor_layout_panel = false`, `monitor_layout_minimum_monitors = 1`, and thresholds above 2
- [ ] 6.4 Manually verify highlighted-workspace activation, hover non-effects, configuration reload, tree-panel coexistence, and popup close behavior
