## ADDED Requirements

### Requirement: Configurable monitor color palette

The configuration SHALL accept an optional `appearance.monitor_colors` array whose entries are six-digit RGB hex strings in `#RRGGBB` form. The array order SHALL define the color order used for monitors.

#### Scenario: Appearance setting is omitted

- **WHEN** the configuration does not declare `appearance.monitor_colors`
- **THEN** GridSpaces uses the built-in monitor palette `["#32ADE6", "#FF9500", "#34C759", "#FF2D55", "#AF52DE", "#FFCC00"]`

#### Scenario: Custom monitor colors are configured

- **WHEN** `appearance.monitor_colors` contains one or more valid `#RRGGBB` values
- **THEN** GridSpaces stores and applies those colors in the declared order

#### Scenario: Lowercase hex digits are configured

- **WHEN** a configured monitor color uses lowercase hexadecimal digits
- **THEN** GridSpaces accepts it and normalizes it to uppercase

#### Scenario: Configured palette is invalid

- **WHEN** `appearance.monitor_colors` is empty or any entry is not a six-digit `#RRGGBB` value
- **THEN** GridSpaces reports a clear configuration warning
- **AND** uses the complete built-in monitor palette

### Requirement: Monitor color configuration is documented

The configuration reference SHALL document the optional `appearance.monitor_colors` setting, accepted hex syntax, built-in palette, monitor ordering, palette cycling, and invalid-value fallback.

#### Scenario: User consults the configuration reference

- **WHEN** a user reads `docs/configuration.md`
- **THEN** the document contains a valid `[appearance]` example
- **AND** explains how configured colors are assigned and how omitted or invalid values behave
