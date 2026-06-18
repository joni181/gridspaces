## ADDED Requirements

### Requirement: Display a popup grid of all known workspaces

GridSpaces SHALL display all known workspaces (including empty persistent workspaces) as tiles in a popup overview window when the grid is opened.

#### Scenario: Opening the overview

- **WHEN** the user triggers the open-grid action
- **THEN** a popup window appears showing one tile per known workspace

#### Scenario: Including empty workspaces

- **WHEN** a known workspace currently has no windows
- **THEN** it is still shown as a tile in the grid (an option to hide empty workspaces is deferred to future work)

### Requirement: Place workspaces by the configured 2D grid layout

GridSpaces SHALL position workspace tiles according to the 2D grid layout defined in the configuration, where each row lists workspace names in column order.

#### Scenario: Rendering the configured layout

- **WHEN** the grid opens and a grid layout is configured
- **THEN** each configured workspace appears at its `(row, column)` position as declared in the configuration

#### Scenario: Ragged rows and empty cells

- **WHEN** the configured rows have differing lengths or contain gaps
- **THEN** the grid renders the rows as declared, leaving missing cells as empty space (no tile is drawn there)

### Requirement: Overflow region for ungridded workspaces

GridSpaces SHALL surface any known workspace that has windows but is not placed in the configured grid in a single overflow row appended below the configured grid, so that no workspace with windows is ever hidden.

#### Scenario: Workspace with windows not in the grid

- **WHEN** a workspace holds at least one window and is not assigned a position in the configured grid
- **THEN** it appears as a tile in a single overflow row rendered below the configured grid

#### Scenario: Empty workspace not in the grid

- **WHEN** a workspace has no windows and is not placed in the configured grid
- **THEN** it is not shown (neither in the grid nor in the overflow region)

### Requirement: Tiles display the app icons of open windows

Each workspace tile SHALL display the application icons of the windows currently open in that workspace.

#### Scenario: Rendering app icons

- **WHEN** a workspace has open windows
- **THEN** its tile shows the icon of each distinct owning application

#### Scenario: Empty tile appearance

- **WHEN** a workspace has no open windows
- **THEN** its tile is rendered in an empty state (no app icons) while still identifying the workspace

#### Scenario: Workspace identity is visible

- **WHEN** any tile is rendered
- **THEN** the workspace's name/identifier (e.g. `1`, `2`, `Q`, `W`) is displayed on the tile so it can serve as a reminder of the workspace's keyboard shortcut, regardless of whether the workspace has windows

### Requirement: Per-monitor outline color

Each tile SHALL display a colored outline that encodes the monitor the workspace is currently assigned to, with one distinct color per monitor.

#### Scenario: Distinct colors per monitor

- **WHEN** workspaces are spread across multiple monitors
- **THEN** tiles on the same monitor share one outline color and tiles on different monitors use different outline colors

#### Scenario: Reflecting a monitor change

- **WHEN** a workspace's monitor assignment changes (e.g. after a move-to-monitor action)
- **THEN** its tile's outline color updates to reflect the new monitor

### Requirement: Open behavior and initial highlight

When opened, the grid SHALL present immediately with the highlight placed on the currently focused workspace.

#### Scenario: Highlight starts on the current workspace

- **WHEN** the grid opens
- **THEN** the tile of the currently focused workspace is highlighted as the initial selection

#### Scenario: Fresh state on open

- **WHEN** the grid opens
- **THEN** the displayed workspaces, app icons, and monitor outlines reflect a fresh read of AeroSpace state
