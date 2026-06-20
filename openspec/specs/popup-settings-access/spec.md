# popup-settings-access Specification

## Purpose
TBD - created by archiving change replace-popup-shortcut-footer-with-settings. Update Purpose after archive.
## Requirements
### Requirement: Popup omits the persistent shortcut legend

The GridSpaces popup SHALL display the workspace grid without a persistent footer or other always-visible legend listing navigation and action keyboard shortcuts.

#### Scenario: Popup is displayed

- **WHEN** the GridSpaces popup opens
- **THEN** no keyboard-shortcut legend is displayed below the workspace grid

### Requirement: Popup provides a settings button

The GridSpaces popup SHALL display an operable settings button at the top right of its header, and the button SHALL expose hover help identifying both its purpose and the `Command+,` shortcut.

#### Scenario: User hovers over the settings button

- **WHEN** the pointer hovers over the settings button
- **THEN** the popup shows help text equivalent to `Open Config (⌘,)`

#### Scenario: User clicks the settings button

- **WHEN** the user activates the settings button
- **THEN** GridSpaces opens `~/.config/gridspaces/gridspaces.toml` using the macOS-associated default application for the file

#### Scenario: Assistive technology inspects the settings button

- **WHEN** an accessibility client inspects the settings button
- **THEN** the control is identified as an action that opens the GridSpaces configuration

### Requirement: Focused Command-comma opens the config

GridSpaces SHALL reserve `Command+,` as a fixed, non-configurable command that opens `~/.config/gridspaces/gridspaces.toml` only while the popup is visible and has keyboard focus.

#### Scenario: Shortcut is pressed in the focused popup

- **GIVEN** the GridSpaces popup is visible and has keyboard focus
- **WHEN** the user presses `Command+,`
- **THEN** GridSpaces opens the config file using the same action as the settings button
- **AND** the keystroke is not processed as another popup binding

#### Scenario: Popup is not focused

- **GIVEN** the GridSpaces popup is not the key window
- **WHEN** the user presses `Command+,`
- **THEN** GridSpaces does not handle the keystroke

#### Scenario: Existing keybinding configuration is loaded

- **WHEN** GridSpaces loads a configuration containing custom in-popup bindings
- **THEN** `Command+,` remains the settings command without requiring or accepting a keybinding setting

### Requirement: Config file exists before opening

Before invoking the default application, GridSpaces SHALL ensure that `~/.config/gridspaces/gridspaces.toml` exists without modifying an existing file.

#### Scenario: Config file already exists

- **GIVEN** `~/.config/gridspaces/gridspaces.toml` already exists
- **WHEN** the user opens the config from the popup
- **THEN** GridSpaces opens that file without changing its contents

#### Scenario: Config directory does not exist

- **GIVEN** `~/.config/gridspaces` does not exist
- **WHEN** the user opens the config from the popup
- **THEN** GridSpaces creates the directory
- **AND** creates an empty `gridspaces.toml`
- **AND** opens the new file

#### Scenario: Config directory exists but file does not

- **GIVEN** `~/.config/gridspaces` exists
- **AND** `gridspaces.toml` does not exist
- **WHEN** the user opens the config from the popup
- **THEN** GridSpaces creates an empty `gridspaces.toml`
- **AND** opens the new file

### Requirement: Config-open failures are visible

GridSpaces SHALL report an actionable error in the popup when it cannot create or open the config file.

#### Scenario: Config path cannot be prepared

- **WHEN** directory or file creation fails
- **THEN** the popup displays an error identifying that the GridSpaces config could not be prepared
- **AND** no existing config file is overwritten

#### Scenario: Default application rejects the open request

- **GIVEN** the config file exists
- **WHEN** macOS cannot open it with an associated application
- **THEN** the popup displays an error identifying that the GridSpaces config could not be opened

