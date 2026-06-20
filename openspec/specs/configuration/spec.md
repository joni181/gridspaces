# configuration Specification

## Purpose
TBD - created by archiving change add-workspace-grid. Update Purpose after archive.
## Requirements
### Requirement: TOML configuration dotfile

GridSpaces SHALL read its configuration from a TOML dotfile, mirroring AeroSpace's configuration style, located at `~/.config/gridspaces/gridspaces.toml`.

#### Scenario: Loading configuration on demand

- **WHEN** GridSpaces starts or reloads configuration
- **THEN** it reads `~/.config/gridspaces/gridspaces.toml` and applies the declared settings

#### Scenario: Missing configuration file

- **WHEN** no configuration file exists
- **THEN** GridSpaces applies built-in defaults for the grid layout, keybindings, and toggles, and still functions

### Requirement: Configurable grid layout

The configuration SHALL define the 2D grid layout as an ordered list of rows, where each row lists workspace names in column order, and rows MAY be ragged (differing lengths / gaps).

#### Scenario: Declaring a keyboard-style layout

- **WHEN** the configuration declares rows `["1","2","3","4","5"]`, `["Q","W","E","R","T"]`, `["A","S","D","F","G"]`, `["Y","X","C","V","B"]`
- **THEN** GridSpaces places those workspaces at the corresponding `(row, column)` positions

#### Scenario: Workspace listed in the layout but unknown to AeroSpace

- **WHEN** a workspace name in the layout is not currently reported by AeroSpace
- **THEN** GridSpaces still reserves its grid position and renders it as an empty tile

### Requirement: Remappable keybindings with defaults

The configuration SHALL allow remapping the in-grid keybindings, providing sensible defaults when unspecified.

#### Scenario: Default keybindings

- **WHEN** keybindings are not specified in the configuration
- **THEN** GridSpaces uses defaults: navigation `h`/`j`/`k`/`l` (and arrow keys), confirm `Enter`, cancel `Esc`, and four directional move-to-monitor actions `Shift+h`/`Shift+j`/`Shift+k`/`Shift+l` (and `Shift`+arrows) for left/down/up/right

#### Scenario: Overriding a keybinding

- **WHEN** the configuration specifies a custom key for a navigation or action binding
- **THEN** GridSpaces uses the custom key in place of the default for that binding

### Requirement: Behavior toggles

The configuration SHALL expose behavior toggles, including whether directional navigation and switching wrap at grid edges, whether the close-all-windows action requires a confirmation keypress, the move-to-monitor mode (directional vs. cycle), and whether move-to-monitor wraps around at the last monitor.

#### Scenario: Configuring edge wrapping

- **WHEN** the wrap toggle is set in the configuration
- **THEN** both in-grid navigation and headless directional switching honor that wrap setting

#### Scenario: Configuring close confirmation

- **WHEN** the close-confirmation toggle is unspecified
- **THEN** GridSpaces requires a confirmation keypress before closing all windows (enabled by default)

#### Scenario: Disabling close confirmation

- **WHEN** the close-confirmation toggle is set to disabled
- **THEN** the close-all-windows action closes immediately without prompting

#### Scenario: Default move-to-monitor mode is directional

- **WHEN** the move-to-monitor mode is unspecified
- **THEN** GridSpaces uses directional mode with four directional move actions

#### Scenario: Selecting cycle move mode

- **WHEN** the move-to-monitor mode is set to cycle
- **THEN** GridSpaces uses next/prev cycle move actions instead of the four directional actions

### Requirement: Configuration validation and error reporting

GridSpaces SHALL validate the configuration and report errors clearly without crashing, falling back to defaults for invalid or missing values.

#### Scenario: Invalid configuration value

- **WHEN** the configuration contains a malformed or invalid value
- **THEN** GridSpaces reports a clear error identifying the problem and falls back to the default for the affected setting

### Requirement: Global shortcuts are configured in AeroSpace

Global shortcuts (open-grid and headless directional switching) SHALL be configured as AeroSpace bindings that execute GridSpaces CLI commands, and the setup steps SHALL be documented for the user.

#### Scenario: Documented setup

- **WHEN** a user wants global shortcuts
- **THEN** the documentation describes the AeroSpace binding(s) that execute the GridSpaces CLI commands (open-grid and directional switch), requiring no changes to AeroSpace source

