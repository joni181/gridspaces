# grid-navigation Specification

## Purpose
TBD - created by archiving change add-workspace-grid. Update Purpose after archive.
## Requirements
### Requirement: In-grid highlight navigation

While the grid is open, GridSpaces SHALL move a highlight between workspace tiles in response to the navigation keys, defaulting to `h`/`j`/`k`/`l` (left/down/up/right) and remappable via configuration.

#### Scenario: Moving the highlight

- **WHEN** the grid is open and the user presses a navigation key
- **THEN** the highlight moves one cell in the corresponding direction to the nearest tile in that direction

#### Scenario: Arrow keys also navigate

- **WHEN** the grid is open and the user presses an arrow key
- **THEN** the highlight moves in the corresponding direction, equivalently to the default `hjkl` keys

#### Scenario: Navigation does not switch workspaces

- **WHEN** the user moves the highlight within the grid
- **THEN** the currently focused AeroSpace workspace does NOT change as a result of navigation alone

### Requirement: Navigation skips empty cells

Highlight navigation SHALL skip empty cells (gaps in ragged rows) and land on the next tile in the direction of travel.

#### Scenario: Skipping a gap

- **WHEN** the highlight moves in a direction where the adjacent cell is empty but a tile exists further along
- **THEN** the highlight lands on the next non-empty tile in that direction

#### Scenario: No tile in the direction

- **WHEN** the highlight moves in a direction where no tile exists and wrapping is disabled
- **THEN** the highlight stays on its current tile

### Requirement: Edge-wrap behavior is configurable

Highlight navigation at the grid edges SHALL wrap or stop according to the configured wrap setting.

#### Scenario: Wrapping enabled

- **WHEN** wrapping is enabled and the highlight moves past an edge
- **THEN** it continues from the opposite edge of the same row or column

#### Scenario: Wrapping disabled

- **WHEN** wrapping is disabled and the highlight moves past an edge
- **THEN** the highlight remains on the edge tile (no-op)

### Requirement: Navigate into the overflow region

Highlight navigation SHALL allow reaching tiles in the overflow region.

#### Scenario: Entering overflow

- **WHEN** the user navigates downward past the last configured grid row and an overflow region exists
- **THEN** the highlight moves into the overflow region

### Requirement: Focus the highlighted workspace on close

When the grid is closed via the confirm/close action, GridSpaces SHALL switch focus to the highlighted workspace.

#### Scenario: Confirming a selection

- **WHEN** the user closes the grid with the confirm action (default `Enter`) while a workspace is highlighted
- **THEN** the grid closes and AeroSpace focus switches to the highlighted workspace

#### Scenario: Highlight unchanged

- **WHEN** the user confirms without having moved the highlight away from the initially focused workspace
- **THEN** the focused workspace is unchanged after the grid closes

### Requirement: Cancel without switching

GridSpaces SHALL provide a cancel action (default `Esc`) that closes the grid without changing the focused workspace.

#### Scenario: Cancelling the overview

- **WHEN** the user presses the cancel key while the grid is open
- **THEN** the grid closes and the focused workspace remains whatever it was before the grid opened, regardless of where the highlight was

