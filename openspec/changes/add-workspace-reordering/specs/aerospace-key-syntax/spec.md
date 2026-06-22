## MODIFIED Requirements

### Requirement: Keys section uses hotkey-first syntax

The `[keys]` section in the TOML config SHALL use `hotkey-combo = 'command'` syntax, where the TOML key is the hotkey combination string and the TOML value is the GridSpaces command. This matches AeroSpace's `[mode.main.binding]` convention.

Valid commands are: `left`, `right`, `up`, `down`, `confirm`, `cancel`, `close-all`, `move-workspace <left|right|up|down>`, and `move-to-display <left|right|up|down|next|previous>`.

#### Scenario: Named command binding

- **WHEN** the config contains `h = 'left'` under `[keys]`
- **THEN** pressing `h` triggers the `left` action

#### Scenario: Argument-style movement binding

- **WHEN** the config contains `alt-h = 'move-workspace left'` under `[keys]`
- **THEN** pressing `Alt+h` triggers workspace-content movement to the left

#### Scenario: Unknown command is rejected with warning

- **WHEN** the config contains `h = 'teleport'` under `[keys]`
- **THEN** the binding is ignored and a warning is emitted naming the unrecognized command

#### Scenario: Removed movement command is rejected with warning

- **WHEN** the config contains `shift-h = 'move-left'` under `[keys]`
- **THEN** the binding is ignored and a warning is emitted naming the unrecognized command

#### Scenario: Duplicate hotkey binding is rejected with warning

- **WHEN** the config contains two entries with the same hotkey string under `[keys]`
- **THEN** the second entry is ignored and a warning is emitted

### Requirement: Modifier separator is a hyphen

Hotkey combination strings SHALL use `-` as the separator between modifiers and the key, such as `shift-h` or `ctrl-alt-j`. The `+` character is not a valid separator and SHALL be rejected.

Valid modifiers are: `shift`, `ctrl`, `alt`, and `cmd`.

#### Scenario: Modifier-key with hyphen separator is accepted

- **WHEN** the config contains `shift-h = 'move-to-display left'` under `[keys]`
- **THEN** the binding is parsed successfully and `Shift+h` triggers display movement to the left

#### Scenario: Plus separator is rejected

- **WHEN** the config contains `shift+h = 'move-to-display left'` under `[keys]`
- **THEN** the binding is rejected with a warning indicating an invalid hotkey string

#### Scenario: Multiple modifiers are accepted

- **WHEN** the config contains `ctrl-shift-j = 'move-workspace down'` under `[keys]`
- **THEN** the binding is parsed and `Ctrl+Shift+j` triggers workspace-content movement down

### Requirement: Config loader rejects old plus-separator syntax with a warning

To help users correct invalid hotkeys, the parser SHALL detect `+` in a hotkey string and emit a descriptive warning that names the affected key and suggests the corrected `-`-separated form, rather than silently dropping the binding.

#### Scenario: Plus-separator triggers correction warning

- **WHEN** the config contains `shift+h = 'move-to-display left'` under `[keys]`
- **THEN** the binding is skipped and the warning message mentions `shift+h` and suggests `shift-h`
