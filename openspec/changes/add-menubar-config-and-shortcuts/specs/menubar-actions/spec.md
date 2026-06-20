## ADDED Requirements

### Requirement: Status menu exposes all application actions

The GridSpaces status menu SHALL contain actionable items for `Open GridSpaces`, `Reload Configuration`, `Open Config`, and `Quit GridSpaces`.

#### Scenario: User opens the status menu

- **WHEN** the user opens the GridSpaces status menu
- **THEN** the four actions are available
- **AND** `Open Config` appears after `Reload Configuration`
- **AND** `Quit GridSpaces` remains separated from the preceding actions

### Requirement: Open Config reuses the canonical config-opening action

The `Open Config` status-menu item SHALL use the same config preparation and macOS default-application opening behavior as the popup settings button and focused `Command+,` shortcut.

#### Scenario: Existing config is opened from the menu

- **GIVEN** `~/.config/gridspaces/gridspaces.toml` exists
- **WHEN** the user selects `Open Config`
- **THEN** GridSpaces opens the file with its macOS-associated default application
- **AND** does not modify the file

#### Scenario: Missing config is opened from the menu

- **GIVEN** the GridSpaces config file or its parent directory does not exist
- **WHEN** the user selects `Open Config`
- **THEN** GridSpaces creates the missing directory and an empty config file
- **AND** opens the new file with its macOS-associated default application

#### Scenario: Config cannot be prepared or opened

- **WHEN** the menu action cannot prepare or open the config file
- **THEN** GridSpaces presents an actionable error using its existing popup error surface

### Requirement: Status-menu actions have keyboard equivalents

GridSpaces SHALL assign a keyboard equivalent to every actionable status-menu item.

#### Scenario: Default menu shortcuts are displayed

- **GIVEN** the user has not configured a custom menubar open shortcut
- **WHEN** the status menu is shown
- **THEN** `Open GridSpaces` displays `Control+Option+Space`
- **AND** `Reload Configuration` displays `Command+R`
- **AND** `Open Config` displays `Command+,`
- **AND** `Quit GridSpaces` displays `Command+Q`

#### Scenario: Fixed shortcut activates its menu action

- **WHEN** the status menu is active and the user presses `Command+R`, `Command+,`, or `Command+Q`
- **THEN** GridSpaces invokes the corresponding reload, config-open, or quit action

### Requirement: Open menu shortcut tracks active configuration

The `Open GridSpaces` menu item's keyboard equivalent SHALL reflect the active configuration and SHALL update after configuration reload.

#### Scenario: Custom open shortcut is loaded at startup

- **GIVEN** `[menubar].open_shortcut` contains a valid custom hotkey
- **WHEN** GridSpaces starts and loads the configuration
- **THEN** `Open GridSpaces` displays and responds to that menu key equivalent

#### Scenario: Open shortcut changes on reload

- **GIVEN** the active open shortcut differs from the value now stored in the config file
- **WHEN** configuration reload succeeds
- **THEN** the `Open GridSpaces` menu item uses the newly configured equivalent

#### Scenario: Reload is rejected

- **GIVEN** GridSpaces has an active open shortcut
- **WHEN** configuration reload fails and the new configuration is not applied
- **THEN** the `Open GridSpaces` menu item keeps the previous equivalent
