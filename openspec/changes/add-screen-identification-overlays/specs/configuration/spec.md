## ADDED Requirements

### Requirement: Configurable screen identification borders

The configuration SHALL accept `appearance.screen_borders` as a boolean and `appearance.screen_border_width` as a positive integer measured in logical screen pixels.

#### Scenario: Screen border settings are omitted

- **WHEN** the configuration omits `appearance.screen_borders` and `appearance.screen_border_width`
- **THEN** GridSpaces enables screen borders
- **AND** uses a border width of 5 logical pixels

#### Scenario: Screen borders are disabled

- **WHEN** `appearance.screen_borders` is `false`
- **THEN** GridSpaces does not draw screen identification borders

#### Scenario: Custom screen border width is configured

- **WHEN** `appearance.screen_border_width` is a positive integer
- **THEN** GridSpaces uses that value as the screen identification border width

#### Scenario: Screen border width is invalid

- **WHEN** `appearance.screen_border_width` is zero or negative
- **THEN** GridSpaces reports a clear configuration warning
- **AND** uses the default width of 5 logical pixels

### Requirement: Configurable minimum monitor count for screen identification

The configuration SHALL accept `appearance.screen_minimum_monitors` as a positive integer defining the minimum number of connected monitors required to show screen identification borders.

#### Scenario: Minimum monitor count is omitted

- **WHEN** the configuration omits `appearance.screen_minimum_monitors`
- **THEN** GridSpaces requires at least 2 connected monitors before showing screen identification overlays

#### Scenario: Custom minimum monitor count is configured

- **WHEN** `appearance.screen_minimum_monitors` is a positive integer
- **THEN** GridSpaces uses that value as the minimum connected monitor count for screen identification overlays

#### Scenario: Minimum monitor count is one

- **WHEN** `appearance.screen_minimum_monitors` is `1`
- **THEN** GridSpaces permits screen identification overlays in a single-monitor setup

#### Scenario: Minimum monitor count is invalid

- **WHEN** `appearance.screen_minimum_monitors` is zero or negative
- **THEN** GridSpaces reports a clear configuration warning
- **AND** uses the default minimum of 2 connected monitors

### Requirement: Screen identification appearance is documented

The configuration reference SHALL document the screen border and minimum-monitor settings, their defaults, border-width units, their relationship to `appearance.monitor_colors`, and that screen infill is deferred for performance reasons.

#### Scenario: User consults the configuration reference

- **WHEN** a user reads `docs/configuration.md`
- **THEN** the document contains a valid `[appearance]` example for screen borders and minimum monitor count
- **AND** explains that physical screens and their workspace tiles use the same monitor color
- **AND** explains how omitted or invalid values behave
