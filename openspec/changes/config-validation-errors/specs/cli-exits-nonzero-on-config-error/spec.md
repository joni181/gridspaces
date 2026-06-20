## ADDED Requirements

### Requirement: `reload-config` validates config before sending IPC and exits non-zero on error
When `gridspaces reload-config` is run and the config file has errors, the CLI SHALL print each error to stderr, exit with a non-zero status code, and NOT send the `reloadConfig` IPC message to the agent.

#### Scenario: Invalid config aborts reload and exits non-zero
- **WHEN** `gridspaces reload-config` is run with a broken config file
- **THEN** the process exits with a non-zero status
- **THEN** error messages are written to stderr
- **THEN** no IPC message is sent to the agent

#### Scenario: Valid config with warnings still reloads and prints warnings to stderr
- **WHEN** `gridspaces reload-config` is run with a config file that has warnings but no errors
- **THEN** the IPC message is sent to the agent
- **THEN** warnings are written to stderr
- **THEN** the process exits with status 0

#### Scenario: Valid config with no issues reloads cleanly
- **WHEN** `gridspaces reload-config` is run with a fully valid config file
- **THEN** the IPC message is sent to the agent
- **THEN** nothing is written to stderr
- **THEN** the process exits with status 0

### Requirement: `focus` exits non-zero on config errors
When `gridspaces focus` is run and the config file has errors, the CLI SHALL print each error to stderr and exit with a non-zero status code instead of continuing with built-in defaults.

#### Scenario: `focus` with broken config exits non-zero
- **WHEN** `gridspaces focus --direction left` is run with a config file that has errors
- **THEN** the process exits with a non-zero status
- **THEN** error messages are written to stderr
- **THEN** no focus action is performed

#### Scenario: `focus` with warnings still executes
- **WHEN** `gridspaces focus --direction left` is run with a config that has warnings but no errors
- **THEN** warnings are written to stderr
- **THEN** the focus action is performed
- **THEN** the process exits with status 0
