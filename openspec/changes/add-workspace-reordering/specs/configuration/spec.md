## MODIFIED Requirements

### Requirement: Remappable keybindings with defaults

The configuration SHALL allow remapping the in-grid keybindings, providing sensible defaults when unspecified. Action values that take a direction SHALL use argument-style command strings.

#### Scenario: Default keybindings

- **WHEN** keybindings are not specified in the configuration
- **THEN** GridSpaces uses defaults: navigation `h`/`j`/`k`/`l` (and arrow keys), confirm `Enter`, cancel `Esc`, workspace-content movement `Alt+h`/`Alt+j`/`Alt+k`/`Alt+l` for left/down/up/right, and directional move-to-display actions `Shift+h`/`Shift+j`/`Shift+k`/`Shift+l` (and `Shift`+arrows) for left/down/up/right

#### Scenario: Canonical workspace movement syntax

- **WHEN** the configuration maps a hotkey to `move-workspace left`, `move-workspace down`, `move-workspace up`, or `move-workspace right`
- **THEN** GridSpaces invokes workspace-content movement in that grid direction

#### Scenario: Canonical display movement syntax

- **WHEN** the configuration maps a hotkey to `move-to-display left`, `move-to-display down`, `move-to-display up`, `move-to-display right`, `move-to-display next`, or `move-to-display previous`
- **THEN** GridSpaces invokes the corresponding display movement action

#### Scenario: Removed display movement syntax

- **WHEN** the configuration uses `move-left`, `move-down`, `move-up`, `move-right`, `move-next`, or `move-previous`
- **THEN** GridSpaces treats the value as an unknown command
- **AND** does not create a binding for it
- **AND** reports the configuration validation error

#### Scenario: Overriding a keybinding

- **WHEN** the configuration specifies a custom key for a navigation or action binding
- **THEN** GridSpaces uses the custom key in place of the default for that binding
