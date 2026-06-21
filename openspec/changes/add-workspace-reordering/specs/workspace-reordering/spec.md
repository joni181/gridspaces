## ADDED Requirements

### Requirement: Move workspace contents directionally

GridSpaces SHALL provide in-grid actions that move the complete snapshotted window set of the highlighted configured workspace to the nearest configured workspace tile in the requested left, down, up, or right direction. The grid SHALL remain open during and after the action.

#### Scenario: Move into an empty workspace

- **WHEN** workspace `B` is highlighted, contains windows, and the user invokes `move-workspace left` toward an empty configured workspace `A`
- **THEN** GridSpaces moves every snapshotted window from `B` to `A`
- **AND** workspace `B` becomes empty
- **AND** the highlight moves to workspace `A`
- **AND** the grid remains open

#### Scenario: No destination in the requested direction

- **WHEN** the highlighted workspace has no configured workspace tile in the requested direction
- **THEN** the action is a no-op
- **AND** the highlight remains unchanged
- **AND** no error is shown

#### Scenario: Gap between configured workspaces

- **WHEN** blank grid cells exist between the highlighted workspace and the next configured workspace in the requested direction
- **THEN** GridSpaces uses the nearest configured workspace beyond the gaps as the destination

#### Scenario: Reordering does not wrap

- **WHEN** the highlighted workspace is at an edge and the user invokes movement past that edge
- **THEN** the action is a no-op even if navigation wrapping is enabled

#### Scenario: Overflow workspace is highlighted

- **WHEN** an overflow workspace is highlighted and the user invokes a workspace-movement action
- **THEN** the action is a no-op
- **AND** no configured workspace contents are changed

### Requirement: Swap occupied workspace contents

When both source and destination contain windows, GridSpaces SHALL exchange their snapshotted window sets rather than merge them.

#### Scenario: Swap two occupied workspaces

- **GIVEN** workspace `A` contains Safari and Terminal windows
- **AND** adjacent workspace `B` contains Photos and Notes windows
- **WHEN** workspace `B` is highlighted and the user invokes `move-workspace left`
- **THEN** the original Safari and Terminal windows belong to workspace `B`
- **AND** the original Photos and Notes windows belong to workspace `A`
- **AND** the highlight moves from `B` to `A`

#### Scenario: Empty source swaps with occupied destination

- **WHEN** the highlighted source workspace is empty and the destination workspace contains windows
- **THEN** the destination's snapshotted windows move to the source
- **AND** the destination becomes empty
- **AND** the highlight moves to the destination tile

### Requirement: Preserve window identity with best-effort layout retention

GridSpaces SHALL move windows by AeroSpace window ID and SHALL preserve which windows belong to each exchanged set. GridSpaces SHALL NOT claim to preserve nested tiling containers, split ratios, exact tile positions, or workspace focus history when AeroSpace's public interface cannot represent them.

#### Scenario: Window identity is preserved

- **WHEN** a workspace-content move completes successfully
- **THEN** the same snapshotted window IDs exist in the destination workspace assigned to their set
- **AND** GridSpaces does not close and recreate application windows

#### Scenario: Complex tiling layout

- **WHEN** a moved workspace contains nested containers or custom split ratios
- **THEN** GridSpaces moves all snapshotted windows
- **AND** the resulting AeroSpace layout MAY be re-tiled because exact tree preservation is not supported

### Requirement: Serialize, verify, and recover workspace moves

GridSpaces SHALL allow at most one workspace-content move at a time, verify the final membership of surviving snapshotted windows, and attempt to return them to their original workspaces after a partial failure.

#### Scenario: Repeated movement input while busy

- **WHEN** a workspace-content move is in progress and another workspace-content move shortcut is pressed
- **THEN** GridSpaces ignores the additional move request

#### Scenario: Partial AeroSpace failure

- **WHEN** AeroSpace fails after one or more individual windows have moved
- **THEN** GridSpaces attempts to move every surviving snapshotted window back to its original workspace
- **AND** refreshes workspace state
- **AND** keeps the highlight on the original source workspace
- **AND** reports that the operation failed

#### Scenario: Window closes during movement

- **WHEN** a snapshotted window no longer exists before its move or rollback command runs
- **THEN** GridSpaces continues handling the remaining snapshotted windows
- **AND** does not move windows created after the initial snapshots as part of that operation

### Requirement: Visual workspace move-mode hint

GridSpaces SHALL visually indicate availability of workspace-content movement while the popup is key and the exact common modifier set of all four configured directional workspace-movement bindings is held.

#### Scenario: Default Alt modifier is pressed

- **WHEN** the default `Alt+h/j/k/l` bindings are active and the user holds only `Alt`
- **THEN** workspace tiles display a subtle shake animation until `Alt` is released or the popup closes

#### Scenario: Additional modifier distinguishes another chord

- **WHEN** the common workspace-movement modifier is `Alt` and the user holds `Alt+Ctrl`
- **THEN** the shake hint is not active

#### Scenario: Direction bindings use different modifiers

- **WHEN** the four configured workspace-movement bindings do not share one non-empty modifier set
- **THEN** GridSpaces does not show the modifier-only shake hint
- **AND** each configured full shortcut remains functional

#### Scenario: Reduce Motion is enabled

- **WHEN** the movement modifier is held and macOS Reduce Motion is enabled
- **THEN** GridSpaces uses a static visual emphasis instead of shaking the tiles
