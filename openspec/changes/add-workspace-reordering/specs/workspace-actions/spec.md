## MODIFIED Requirements

### Requirement: Move the highlighted workspace to an adjacent monitor

GridSpaces SHALL provide in-grid `move-to-display <target>` actions that move the highlighted workspace to another monitor. In directional mode, the supported targets SHALL be `left`, `right`, `up`, and `down`; each SHALL have its own remappable shortcut and map to AeroSpace's directional `move-workspace-to-monitor` form. In cycle mode, the targets SHALL be `next` and `previous`. The action SHALL target the highlighted workspace directly via `move-workspace-to-monitor --workspace <name>` and SHALL NOT change the focused workspace.

#### Scenario: Moving in a physical direction

- **WHEN** the user triggers a directional action such as `move-to-display right` on a highlighted workspace and a monitor exists in that physical direction
- **THEN** the workspace is moved to the monitor in that direction
- **AND** the tile's monitor outline color updates to reflect the new monitor

#### Scenario: No monitor in the requested direction

- **WHEN** the user triggers a directional move-to-display action and no monitor exists in that direction
- **THEN** the action is a no-op unless monitor wrap-around is enabled in configuration
- **AND** no error is shown
- **AND** the highlight remains on the same workspace tile

#### Scenario: Cycle mode alternative

- **WHEN** the configuration selects cycle mode instead of directional mode
- **THEN** `move-to-display next` and `move-to-display previous` move the highlighted workspace through monitors in a fixed cycle order, wrapping at the ends

#### Scenario: Focus is unchanged by the move

- **WHEN** the highlighted workspace is not the focused workspace and a move-to-display action is triggered
- **THEN** the highlighted workspace is moved and the focused workspace remains unchanged

#### Scenario: Highlight follows the moved workspace

- **WHEN** the highlighted workspace is moved to another monitor
- **THEN** the highlight remains on that same workspace tile after the move
- **AND** the grid stays open

#### Scenario: Single monitor present

- **WHEN** the user triggers any move-to-display action and only one monitor exists
- **THEN** the action is a no-op and no error is shown
