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

The configuration SHALL accept `appearance.screen_minimum_monitors` as a positive integer defining the minimum number of connected monitors required to show screen identification borders or infill.

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

### Requirement: Configurable screen identification infill

The configuration SHALL accept `appearance.screen_infill` as a boolean and `appearance.screen_infill_transparency` as an integer percentage from 0 through 100 inclusive. Zero percent SHALL mean fully opaque and 100 percent SHALL mean fully transparent.

#### Scenario: Screen infill settings are omitted

- **WHEN** the configuration omits `appearance.screen_infill` and `appearance.screen_infill_transparency`
- **THEN** GridSpaces disables screen infill
- **AND** retains a default infill transparency of 80 percent for use if infill is enabled

#### Scenario: Screen infill is enabled

- **WHEN** `appearance.screen_infill` is `true`
- **THEN** GridSpaces fills each screen identification overlay with that screen's monitor color
- **AND** applies the configured infill transparency

#### Scenario: Fully opaque infill is configured

- **WHEN** `appearance.screen_infill_transparency` is `0`
- **THEN** GridSpaces renders enabled infill fully opaque

#### Scenario: Fully transparent infill is configured

- **WHEN** `appearance.screen_infill_transparency` is `100`
- **THEN** GridSpaces renders no visible infill

#### Scenario: Screen infill transparency is invalid

- **WHEN** `appearance.screen_infill_transparency` is less than 0 or greater than 100
- **THEN** GridSpaces reports a clear configuration warning
- **AND** uses the default infill transparency of 80 percent

### Requirement: Screen identification appearance is documented

The configuration reference SHALL document the screen border, minimum-monitor, and infill settings, their defaults, border-width units, transparency range and direction, and their relationship to `appearance.monitor_colors`.

#### Scenario: User consults the configuration reference

- **WHEN** a user reads `docs/configuration.md`
- **THEN** the document contains a valid `[appearance]` example for screen borders, minimum monitor count, and infill
- **AND** explains that physical screens and their workspace tiles use the same monitor color
- **AND** explains how omitted or invalid values behave
