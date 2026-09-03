## ADDED Requirements

### Requirement: Configurable monitor layout panel

The configuration SHALL accept optional `appearance.show_monitor_layout_panel` and `appearance.monitor_layout_minimum_monitors` settings. `show_monitor_layout_panel` SHALL be a boolean and default to `true`. `monitor_layout_minimum_monitors` SHALL be a positive integer and default to `2`.

#### Scenario: Appearance settings are omitted

- **WHEN** the configuration omits `appearance.show_monitor_layout_panel` and `appearance.monitor_layout_minimum_monitors`
- **THEN** GridSpaces enables the monitor-layout panel
- **AND** requires at least 2 connected monitors before showing it

#### Scenario: User disables the panel

- **WHEN** `appearance.show_monitor_layout_panel` is `false`
- **THEN** GridSpaces does not show the monitor-layout panel regardless of connected monitor count

#### Scenario: User enables the panel for one monitor

- **WHEN** `appearance.monitor_layout_minimum_monitors` is `1`
- **AND** `appearance.show_monitor_layout_panel` is `true` or omitted
- **THEN** GridSpaces may show the monitor-layout panel when exactly one monitor is connected

#### Scenario: User requires more monitors

- **WHEN** `appearance.monitor_layout_minimum_monitors` is greater than `2`
- **THEN** GridSpaces shows the monitor-layout panel only when at least that many monitors are connected

#### Scenario: Invalid monitor threshold

- **WHEN** `appearance.monitor_layout_minimum_monitors` is zero or negative
- **THEN** GridSpaces reports a clear configuration warning
- **AND** falls back to the default threshold of `2`
- **AND** preserves valid sibling appearance settings

### Requirement: Monitor layout panel configuration is documented

The configuration reference SHALL document the optional `appearance.show_monitor_layout_panel` and `appearance.monitor_layout_minimum_monitors` settings, their defaults, the one-monitor opt-in behavior, and their relationship to `appearance.monitor_colors`.

#### Scenario: User consults the configuration reference

- **WHEN** a user reads `docs/configuration.md`
- **THEN** the document contains valid `[appearance]` examples for enabling, disabling, and showing the monitor-layout panel with one monitor
- **AND** explains that monitor shapes reuse the workspace monitor colors
