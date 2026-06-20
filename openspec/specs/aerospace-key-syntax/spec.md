# aerospace-key-syntax Specification

## Purpose
TBD - created by archiving change aerospace-key-syntax. Update Purpose after archive.
## Requirements
### Requirement: Keys section uses hotkey-first syntax
The `[keys]` section in the TOML config SHALL use `hotkey-combo = 'command'` syntax, where the TOML key is the hotkey combination string and the TOML value is the gridspaces command name. This matches AeroSpace's `[mode.main.binding]` convention.

Valid command names are: `left`, `right`, `up`, `down`, `confirm`, `cancel`, `close-all`, `move-left`, `move-right`, `move-up`, `move-down`, `move-next`, `move-previous`.

#### Scenario: Named command binding
- **WHEN** the config contains `h = 'left'` under `[keys]`
- **THEN** pressing `h` triggers the `left` action

#### Scenario: Unknown command is rejected with warning
- **WHEN** the config contains `h = 'teleport'` under `[keys]`
- **THEN** the binding is ignored and a warning is emitted naming the unrecognized command

#### Scenario: Duplicate hotkey binding is rejected with warning
- **WHEN** the config contains two entries with the same hotkey string under `[keys]`
- **THEN** the second entry is ignored and a warning is emitted

### Requirement: Modifier separator is a hyphen
Hotkey combination strings SHALL use `-` as the separator between modifiers and the key (e.g., `shift-h`, `ctrl-alt-j`). The `+` character is not a valid separator and SHALL be rejected.

Valid modifiers are: `shift`, `ctrl`, `alt`, `cmd`.

#### Scenario: Modifier-key with hyphen separator is accepted
- **WHEN** the config contains `shift-h = 'move-left'` under `[keys]`
- **THEN** the binding is parsed successfully and `shift-h` triggers `move-left`

#### Scenario: Plus separator is rejected
- **WHEN** the config contains `shift+h = 'move-left'` under `[keys]`
- **THEN** the binding is rejected with a warning indicating an invalid hotkey string

#### Scenario: Multiple modifiers are accepted
- **WHEN** the config contains `ctrl-shift-j = 'move-down'` under `[keys]`
- **THEN** the binding is parsed and `ctrl+shift+j` triggers `move-down`

### Requirement: Workspace bindings use hotkey-first syntax with hyphen separator
The `[keys.workspaces]` subtable SHALL use `hotkey-combo = 'workspace-name'` syntax, consistent with the main `[keys]` section. Hotkey strings follow the same `-`-separated format.

#### Scenario: Single-key workspace binding
- **WHEN** the config contains `1 = '1'` under `[keys.workspaces]`
- **THEN** pressing `1` navigates to workspace `1`

#### Scenario: Modified workspace binding
- **WHEN** the config contains `alt-q = 'Q'` under `[keys.workspaces]`
- **THEN** pressing `alt+q` navigates to workspace `Q`

#### Scenario: Empty workspace name is rejected
- **WHEN** the config contains `q = ''` under `[keys.workspaces]`
- **THEN** the binding is ignored and a warning is emitted

### Requirement: Config loader rejects old plus-separator syntax with a warning
To help users migrate, the parser SHALL detect `+` in a hotkey string and emit a descriptive warning that names the affected key and suggests the corrected `-`-separated form, rather than silently dropping the binding.

#### Scenario: Plus-separator triggers migration warning
- **WHEN** the config contains `shift+h = 'move-left'` under `[keys]`
- **THEN** the binding is skipped and the warning message mentions `shift+h` and suggests `shift-h`

### Requirement: Default config uses aerospace-key-syntax
The built-in defaults (`KeyBindings.defaults`) and the bundled example config (`config/gridspaces.toml`) SHALL express all hotkey combinations using the new `hotkey-combo = 'command'` format with `-` separators.

#### Scenario: Default config file is valid under new parser
- **WHEN** `config/gridspaces.toml` is loaded by the new parser
- **THEN** it produces no warnings and all bindings are recognized

