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

### Requirement: App-owned status-menu actions have keyboard equivalents

GridSpaces SHALL assign fixed keyboard equivalents to `Reload Configuration`, `Open Config`, and `Quit GridSpaces`, while `Open GridSpaces` SHALL have no menu key equivalent because its global shortcut is owned by AeroSpace.

#### Scenario: Menu shortcuts are displayed

- **WHEN** the status menu is shown
- **THEN** `Open GridSpaces` displays no shortcut
- **AND** `Reload Configuration` displays `Command+R`
- **AND** `Open Config` displays `Command+,`
- **AND** `Quit GridSpaces` displays `Command+Q`

#### Scenario: Fixed shortcut activates its menu action

- **WHEN** the status menu is active and the user presses `Command+R`, `Command+,`, or `Command+Q`
- **THEN** GridSpaces invokes the corresponding reload, config-open, or quit action

#### Scenario: AeroSpace open binding is not duplicated

- **GIVEN** the user has configured an AeroSpace shortcut that invokes GridSpaces
- **WHEN** GridSpaces constructs or reloads its status menu
- **THEN** GridSpaces does not read or copy that shortcut
- **AND** does not register a separate global shortcut
