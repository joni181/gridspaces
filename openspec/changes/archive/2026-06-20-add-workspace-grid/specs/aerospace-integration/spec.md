## ADDED Requirements

### Requirement: Read workspace state from the AeroSpace CLI

GridSpaces SHALL obtain the list of known workspaces by invoking the AeroSpace CLI (`aerospace list-workspaces --all`) rather than maintaining its own workspace registry.

#### Scenario: Listing all known workspaces

- **WHEN** GridSpaces needs the set of workspaces to display or navigate
- **THEN** it queries `aerospace list-workspaces --all` and treats the returned names as the authoritative set of known workspaces (AeroSpace returns persistent workspaces plus any workspace that currently holds windows)

#### Scenario: Identifying the focused workspace

- **WHEN** GridSpaces needs to know which workspace is currently focused
- **THEN** it queries `aerospace list-workspaces --focused` and uses the result as the current workspace

### Requirement: Read window and application state per workspace

GridSpaces SHALL obtain the windows of each workspace, including the owning application, by invoking `aerospace list-windows` with JSON output, so that tiles can display the app icons of open windows.

#### Scenario: Resolving open apps for a workspace

- **WHEN** GridSpaces renders a workspace tile
- **THEN** it queries the windows for that workspace (e.g. `aerospace list-windows --workspace <name> --json`) and derives the distinct owning applications
- **AND** it resolves each application's icon from the running application / bundle for display

#### Scenario: Workspace with no windows

- **WHEN** a workspace has no open windows
- **THEN** GridSpaces represents it as an empty workspace with no app icons

### Requirement: Read monitor state

GridSpaces SHALL obtain the set of monitors and the monitor each workspace is currently on by invoking the AeroSpace CLI (`aerospace list-monitors`), so that per-monitor outline colors and move-to-monitor actions can be computed.

#### Scenario: Mapping workspaces to monitors

- **WHEN** GridSpaces renders the grid
- **THEN** it determines, for each workspace, which monitor it is assigned to, using AeroSpace CLI output

### Requirement: Execute AeroSpace actions on behalf of the user

GridSpaces SHALL perform workspace operations by invoking AeroSpace CLI commands, and SHALL NOT modify AeroSpace source code or replace AeroSpace functionality.

#### Scenario: Focusing a workspace

- **WHEN** GridSpaces needs to switch the focused workspace
- **THEN** it invokes `aerospace workspace <name>`

#### Scenario: Moving a workspace to another monitor

- **WHEN** GridSpaces needs to move a specific workspace to an adjacent monitor
- **THEN** it invokes `aerospace move-workspace-to-monitor --workspace <name>` with a directional target (`left|down|up|right`) by default, or `next|prev` when cycle mode is configured, moving that workspace without changing the focused workspace

#### Scenario: Closing all windows in a workspace

- **WHEN** GridSpaces needs to close all windows of a workspace
- **THEN** it invokes AeroSpace CLI command(s) that close the windows of that workspace

### Requirement: On-demand state refresh without polling

GridSpaces SHALL read AeroSpace state only on demand — when the grid is opened or when a command runs — and SHALL NOT continuously poll AeroSpace or the Accessibility API in the background.

#### Scenario: Refreshing when the grid opens

- **WHEN** the grid overview is opened
- **THEN** GridSpaces performs a fresh read of workspaces, windows, and monitors before rendering

#### Scenario: Idle cost

- **WHEN** the grid is not open and no command is running
- **THEN** GridSpaces performs no periodic AeroSpace queries

### Requirement: AeroSpace availability

GridSpaces SHALL require the AeroSpace CLI to be available, and SHALL report a clear error when it is missing rather than failing silently.

#### Scenario: AeroSpace CLI not found

- **WHEN** GridSpaces attempts to query AeroSpace and the `aerospace` executable is not available on `PATH`
- **THEN** GridSpaces reports a clear, actionable error indicating AeroSpace is required and does not crash

### Requirement: Single-monitor degradation

GridSpaces SHALL degrade gracefully when only one monitor is present.

#### Scenario: Move-to-monitor with one display

- **WHEN** a move-to-monitor action is requested and only one monitor exists
- **THEN** the action is a no-op and GridSpaces does not error

#### Scenario: Outline color with one display

- **WHEN** the grid renders and only one monitor exists
- **THEN** all tiles use a single monitor outline color (per-monitor differentiation is unnecessary)
