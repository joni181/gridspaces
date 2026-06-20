## ADDED Requirements

### Requirement: ConfigLoadResult carries separate errors and warnings
`ConfigLoadResult` SHALL expose two distinct string arrays: `errors` for fatal conditions that prevent the config from being applied, and `warnings` for non-fatal conditions where a setting was individually ignored but the rest of the config was applied. A result with a non-empty `errors` array SHALL NOT carry a valid new config (callers must not apply it).

#### Scenario: Fatal error produces non-empty errors array
- **WHEN** `ConfigLoader.load()` is called on a file with a TOML parse failure
- **THEN** the returned result has a non-empty `errors` array and an empty `warnings` array

#### Scenario: Partial config issues produce warnings not errors
- **WHEN** the config has a valid TOML structure but one individual setting is invalid (e.g. an empty key binding string)
- **THEN** the returned result has an empty `errors` array and a non-empty `warnings` array describing the skipped setting

#### Scenario: Valid config produces empty errors and empty warnings
- **WHEN** `ConfigLoader.load()` is called on a well-formed config file
- **THEN** both `errors` and `warnings` are empty

### Requirement: Fatal error conditions are classified as errors
The following conditions SHALL produce entries in `errors` (not `warnings`):
- TOML parse failure
- `grid.rows` is missing or contains no workspaces
- `grid.rows` contains duplicate workspace names

Non-fatal conditions (invalid individual settings that fall back to their default) SHALL remain in `warnings`.

#### Scenario: Empty grid rows is an error
- **WHEN** the config contains `[grid]` with `rows = []`
- **THEN** the result has a non-empty `errors` array mentioning the grid

#### Scenario: Duplicate workspace names is an error
- **WHEN** the config contains `rows` with the same workspace name appearing twice
- **THEN** the result has a non-empty `errors` array mentioning duplicate names

#### Scenario: Empty key binding value is a warning
- **WHEN** the config contains a key binding with an empty string value
- **THEN** the result has a non-empty `warnings` array and an empty `errors` array
