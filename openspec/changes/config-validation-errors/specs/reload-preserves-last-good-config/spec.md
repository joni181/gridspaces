## ADDED Requirements

### Requirement: Agent preserves the active config when a reload produces errors
When `reloadConfiguration()` is called and `ConfigLoadResult.errors` is non-empty, the agent SHALL keep the currently-active `GridSpacesConfig` unchanged. The new (invalid) config SHALL NOT be applied.

#### Scenario: Active config is unchanged after failed reload
- **WHEN** the agent has a valid active config and reload is triggered with a broken config file
- **THEN** the active config after the reload attempt is identical to the config before the attempt

#### Scenario: Error message is shown after failed reload
- **WHEN** the agent has a valid active config and reload is triggered with a broken config file
- **THEN** `errorMessage` is set to a non-empty string describing the errors

### Requirement: Agent shows warnings alongside the new config when reload has warnings only
When `reloadConfiguration()` is called and `ConfigLoadResult.errors` is empty but `warnings` is non-empty, the agent SHALL apply the new config and display the warnings.

#### Scenario: New config applied despite warnings
- **WHEN** reload produces a result with no errors and one warning
- **THEN** the active config is updated to the new config

#### Scenario: Warning message is shown after partial reload
- **WHEN** reload produces a result with no errors and one warning
- **THEN** `errorMessage` (or equivalent UI state) contains the warning text

### Requirement: First-launch error falls back to built-in defaults
When the agent starts for the first time (no previous in-memory config) and the config file has errors, the agent SHALL fall back to `GridSpacesConfig.defaults` and display the errors.

#### Scenario: First launch with broken config uses defaults
- **WHEN** the agent starts with no prior config and the config file is invalid
- **THEN** the active config equals `GridSpacesConfig.defaults`
- **THEN** `errorMessage` is non-empty describing the errors
