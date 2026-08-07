## MODIFIED Requirements

### Requirement: Remappable keybindings with defaults

The configuration SHALL allow remapping the in-grid keybindings and the quick-navigate hotkeys, providing sensible defaults when unspecified. Action values that take a direction SHALL use argument-style command strings.

#### Scenario: Default keybindings

- **WHEN** keybindings are not specified in the configuration
- **THEN** GridSpaces uses defaults: navigation `h`/`j`/`k`/`l` (and arrow keys), confirm `Enter`, cancel `Esc`, workspace-content movement `Alt+h`/`Alt+j`/`Alt+k`/`Alt+l` for left/down/up/right, directional move-to-display actions `Shift+h`/`Shift+j`/`Shift+k`/`Shift+l` (and `Shift`+arrows) for left/down/up/right, and quick-navigate `Ctrl+Alt+Shift+h`/`Ctrl+Alt+Shift+j`/`Ctrl+Alt+Shift+k`/`Ctrl+Alt+Shift+l` for left/down/up/right

#### Scenario: Canonical quick-navigate syntax

- **WHEN** the configuration maps a hotkey to `quick-navigate left`, `quick-navigate down`, `quick-navigate up`, or `quick-navigate right`
- **THEN** GridSpaces treats that hotkey as the quick-navigate trigger for that direction
- **AND** watches its modifiers to decide when the gesture ends

#### Scenario: Quick-navigate hotkey without a modifier

- **WHEN** a configured quick-navigate hotkey contains no modifier
- **THEN** GridSpaces reports a configuration warning naming that hotkey and direction
- **AND** keeps the binding, opening the grid without release-based commit

#### Scenario: Overriding a keybinding

- **WHEN** the configuration specifies a custom key for a navigation or action binding
- **THEN** GridSpaces uses the custom key in place of the default for that binding

### Requirement: Global shortcuts are configured in AeroSpace

Global shortcuts (open-grid and quick-navigate) SHALL be configured as AeroSpace bindings that execute GridSpaces CLI commands, and the setup steps SHALL be documented for the user.

#### Scenario: Documented setup

- **WHEN** a user wants global shortcuts
- **THEN** the documentation describes the AeroSpace binding(s) that execute the GridSpaces CLI commands (open-grid and quick-navigate), requiring no changes to AeroSpace source

#### Scenario: Quick-navigate declared in both configs

- **WHEN** a user rebinds quick-navigate to different keys
- **THEN** the documentation states that the AeroSpace binding and the GridSpaces `[keys]` entry must name the same hotkey, because AeroSpace fires it and GridSpaces reads it to learn the held modifiers
