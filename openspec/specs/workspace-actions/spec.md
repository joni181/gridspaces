# workspace-actions Specification

## Purpose
TBD - created by archiving change add-workspace-grid. Update Purpose after archive.
## Requirements
### Requirement: Actions target the highlighted workspace

In-grid actions SHALL operate on the currently highlighted workspace, which may differ from the focused workspace.

#### Scenario: Acting on a non-focused workspace

- **WHEN** the highlight is on a workspace other than the focused one and the user triggers an in-grid action
- **THEN** the action applies to the highlighted workspace, not the focused one

### Requirement: Close all windows in the highlighted workspace

GridSpaces SHALL provide an in-grid action that closes all windows in the highlighted workspace. By default this action SHALL require a confirmation keypress before closing, and the confirmation MAY be disabled via configuration.

#### Scenario: Confirmation required by default

- **WHEN** the user triggers the close-all-windows action on a highlighted workspace that has windows and confirmation is enabled (the default)
- **THEN** GridSpaces prompts for a confirmation keypress and does NOT close any windows until the user confirms

#### Scenario: Confirming the close

- **WHEN** a close-all-windows confirmation is pending and the user presses the confirm key
- **THEN** GridSpaces requests AeroSpace to close all windows in that workspace
- **AND** the tile updates to an empty state once the windows are closed

#### Scenario: Cancelling the close

- **WHEN** a close-all-windows confirmation is pending and the user presses the cancel key (or any non-confirm key)
- **THEN** no windows are closed and the grid remains open with the highlight unchanged

#### Scenario: Confirmation disabled

- **WHEN** the user triggers the close-all-windows action and confirmation is disabled in configuration
- **THEN** GridSpaces immediately requests AeroSpace to close all windows in that workspace without prompting

#### Scenario: Non-persistent workspace disappears

- **WHEN** all windows are closed in a workspace that is not persistent
- **THEN** the workspace is no longer reported by AeroSpace and is removed from the grid (overflow) on the next refresh

#### Scenario: Persistent workspace remains

- **WHEN** all windows are closed in a persistent workspace
- **THEN** the workspace remains in the grid as an empty tile

### Requirement: Move the highlighted workspace to an adjacent monitor

GridSpaces SHALL provide in-grid actions that move the highlighted workspace to an adjacent monitor by physical direction. By default there SHALL be four directional move actions (left/right/up/down), each bound to its own remappable shortcut, mapped to AeroSpace's directional `move-workspace-to-monitor` form. The action SHALL target the highlighted workspace directly (via `move-workspace-to-monitor --workspace <name>`) and SHALL NOT change the focused workspace.

#### Scenario: Moving in a physical direction

- **WHEN** the user triggers a directional move action (e.g. move-right) on a highlighted workspace and a monitor exists in that physical direction
- **THEN** the workspace is moved to the monitor in that direction
- **AND** the tile's monitor outline color updates to reflect the new monitor

#### Scenario: No monitor in the requested direction

- **WHEN** the user triggers a directional move action and no monitor exists in that direction
- **THEN** the action is a no-op (unless monitor wrap-around is enabled in configuration) and no error is shown

#### Scenario: Cycle mode alternative

- **WHEN** the configuration selects cycle mode instead of directional mode
- **THEN** the move action moves the highlighted workspace to the next (or previous) monitor in a fixed cycle order, wrapping at the ends

#### Scenario: Focus is unchanged by the move

- **WHEN** the highlighted workspace is not the focused workspace and a move action is triggered
- **THEN** the highlighted workspace is moved and the focused workspace remains unchanged

#### Scenario: Highlight follows the moved workspace

- **WHEN** the highlighted workspace is moved to another monitor
- **THEN** the highlight remains on that same workspace tile after the move
- **AND** the grid stays open

#### Scenario: Single monitor present

- **WHEN** the user triggers any move action and only one monitor exists
- **THEN** the action is a no-op and no error is shown

