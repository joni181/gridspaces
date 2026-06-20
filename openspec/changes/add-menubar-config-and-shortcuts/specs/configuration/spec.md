## ADDED Requirements

### Requirement: Configurable menubar open shortcut

The configuration SHALL allow `[menubar].open_shortcut` to define the `Open GridSpaces` status-menu key equivalent using the same hyphen-separated hotkey syntax as other GridSpaces key settings.

#### Scenario: Menubar shortcut is not configured

- **WHEN** `[menubar].open_shortcut` is absent
- **THEN** GridSpaces uses `ctrl-alt-space`

#### Scenario: Menubar shortcut is configured

- **WHEN** `[menubar].open_shortcut` contains a valid supported hotkey
- **THEN** GridSpaces stores the normalized hotkey as the active menubar open shortcut

#### Scenario: Menubar shortcut is invalid

- **WHEN** `[menubar].open_shortcut` is empty, malformed, or cannot be represented as a macOS menu key equivalent
- **THEN** GridSpaces reports a configuration warning identifying the setting
- **AND** uses `ctrl-alt-space` for the menubar open shortcut

#### Scenario: Global binding remains externally managed

- **WHEN** GridSpaces applies `[menubar].open_shortcut`
- **THEN** it does not register that shortcut as a system-wide hotkey
- **AND** global invocation remains managed through the user's AeroSpace binding
