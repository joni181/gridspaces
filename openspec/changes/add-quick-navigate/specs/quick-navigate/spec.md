## ADDED Requirements

### Requirement: Pre-highlighted grid open

GridSpaces SHALL provide a `quick-navigate <left|down|up|right>` command that opens the grid overview with the highlight already placed on the workspace adjacent to the focused one in the requested direction.

#### Scenario: Opening in a direction

- **WHEN** quick-navigate is invoked for a direction and the grid is not open
- **THEN** the grid opens
- **AND** the highlight is on the tile that in-grid navigation in that direction would reach from the focused workspace
- **AND** the focused workspace is unchanged so far

#### Scenario: No neighbour in that direction

- **WHEN** the focused workspace has no tile in the requested direction and wrapping is disabled
- **THEN** the highlight stays on the focused workspace

#### Scenario: Focused workspace outside the configured grid

- **WHEN** the focused workspace has no position in the configured grid
- **THEN** the highlight is placed on the configured grid origin

#### Scenario: Invoked while the grid is already open

- **WHEN** quick-navigate is invoked for a direction and the grid is already open
- **THEN** the highlight moves one tile in that direction from its current position
- **AND** release of the trigger modifiers commits the highlighted workspace

### Requirement: Continued navigation while the modifiers are held

While the modifiers of the triggering quick-navigate hotkey remain held, GridSpaces SHALL keep moving the highlight in response to further directional input, without switching workspaces.

#### Scenario: Repeating the quick-navigate hotkey

- **WHEN** the user presses a quick-navigate hotkey again without releasing its modifiers
- **THEN** the highlight advances one further tile in that direction

#### Scenario: Navigation keys with the modifiers held

- **WHEN** the user presses a configured navigation key or an arrow key while the trigger modifiers are held
- **THEN** the highlight moves one tile in the corresponding direction

#### Scenario: Extra steps requested while the grid is still loading

- **WHEN** quick-navigate is invoked again before the grid has finished opening
- **THEN** the additional steps are applied once the highlight exists, so no keypress is lost

### Requirement: Commit on modifier release

Releasing the modifiers of the triggering quick-navigate hotkey SHALL close the grid and focus the highlighted workspace, without a separate confirm keypress.

#### Scenario: Releasing after navigating

- **WHEN** the user releases the trigger modifiers while a workspace is highlighted
- **THEN** the grid closes
- **AND** AeroSpace focus switches to the highlighted workspace

#### Scenario: Partial release

- **WHEN** the user releases some but not all of the trigger modifiers
- **THEN** the switch is committed, because the held combination no longer matches

#### Scenario: Modifiers released before the grid appears

- **WHEN** the shortcut is tapped and the modifiers are already released by the time the grid opens
- **THEN** the grid appears and the highlighted workspace is focused immediately afterwards

#### Scenario: Cancelling instead of committing

- **WHEN** the user presses the cancel key while quick-navigate is active
- **THEN** the grid closes and the focused workspace is unchanged
- **AND** the subsequent modifier release does not switch workspaces

#### Scenario: Nothing to commit

- **WHEN** the trigger modifiers are released while no workspace is highlighted or an error is displayed
- **THEN** the grid stays open and responds to the ordinary grid keys

### Requirement: Release detection without added permissions

Modifier release SHALL be detected without Accessibility, Input Monitoring, or Screen Recording permission, and SHALL NOT depend on the grid panel having become the key window.

#### Scenario: Panel never becomes key

- **WHEN** the grid panel is visible but not key and the trigger modifiers are released
- **THEN** the switch is still committed

### Requirement: Driven by AeroSpace bindings

Quick-navigate SHALL be invocable from AeroSpace bindings, and the hotkey SHALL be declared in the GridSpaces configuration so the grid knows which modifiers to watch.

#### Scenario: Invoked from an AeroSpace binding

- **WHEN** an AeroSpace binding executes `gridspaces quick-navigate <direction>`
- **THEN** GridSpaces performs the pre-highlighted open for that direction

#### Scenario: Hotkey without modifiers

- **WHEN** a quick-navigate hotkey is configured with no modifier
- **THEN** the grid opens pre-highlighted and stays open until the user confirms or cancels
- **AND** the configuration reports a warning
