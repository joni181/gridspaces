## MODIFIED Requirements

### Requirement: Per-monitor outline color

Each tile SHALL display a colored outline that encodes the monitor the workspace is currently assigned to. GridSpaces SHALL select colors from the configured monitor palette according to the monitor's position in AeroSpace's reported monitor list and SHALL cycle through the palette when there are more monitors than configured colors.

#### Scenario: Configured colors are assigned in monitor order

- **GIVEN** the configured monitor palette contains at least as many colors as the connected monitor list
- **WHEN** workspaces are spread across multiple monitors
- **THEN** tiles on the same monitor share the palette color at that monitor's list index
- **AND** tiles on different monitors use their corresponding palette colors

#### Scenario: More monitors than configured colors

- **GIVEN** the configured monitor palette contains fewer colors than the connected monitor list
- **WHEN** GridSpaces renders monitor outlines
- **THEN** it cycles through the configured palette in monitor-list order

#### Scenario: Single or unknown monitor

- **WHEN** only one monitor is connected or a workspace's monitor ID cannot be matched
- **THEN** the tile uses the first color in the active palette

#### Scenario: Reflecting a monitor change

- **WHEN** a workspace's monitor assignment changes (e.g. after a move-to-monitor action)
- **THEN** its tile's outline color updates to the configured color for the new monitor
