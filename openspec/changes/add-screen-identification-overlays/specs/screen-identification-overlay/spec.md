## ADDED Requirements

### Requirement: Identify physical screens with monitor colors

While the workspace grid is open and the connected monitor count meets the configured minimum, GridSpaces SHALL render an identification overlay on every connected screen using the same active monitor palette assignment used by workspace tile outlines.

#### Scenario: Grid opens with multiple screens

- **GIVEN** screen borders are enabled
- **AND** the connected monitor count meets the configured minimum
- **WHEN** the workspace grid opens with multiple connected screens
- **THEN** each screen displays a border in its assigned monitor color
- **AND** workspace tiles assigned to that screen use the same color

#### Scenario: Connected monitor count is below the configured minimum

- **GIVEN** the connected monitor count is less than `appearance.screen_minimum_monitors`
- **WHEN** the workspace grid opens
- **THEN** GridSpaces displays no screen identification borders

#### Scenario: Palette is shorter than the screen list

- **GIVEN** there are more connected screens than configured monitor colors
- **WHEN** GridSpaces renders screen identification overlays
- **THEN** it cycles through the monitor palette using the same monitor-order rules as workspace tile outlines

#### Scenario: Screen borders are disabled

- **GIVEN** screen borders are disabled
- **WHEN** the workspace grid opens
- **THEN** GridSpaces displays no screen identification overlays

### Requirement: Render configurable screen borders

Each screen identification overlay SHALL draw a border at the configured width. The top border SHALL be placed below the menu bar on each screen where macOS reserves menu-bar space.

#### Scenario: Default appearance is used

- **GIVEN** at least 2 monitors are connected
- **WHEN** the workspace grid opens with the default appearance configuration
- **THEN** each connected screen displays a 5-logical-pixel colored border

#### Scenario: Default appearance is used with one monitor

- **GIVEN** exactly 1 monitor is connected
- **WHEN** the workspace grid opens with the default appearance configuration
- **THEN** no screen identification border is visible

#### Scenario: Custom border width is used

- **GIVEN** screen borders are enabled with a custom valid width
- **WHEN** the overlay is rendered
- **THEN** the complete border is visible inside the screen bounds at the configured width

#### Scenario: A screen has a menu bar

- **GIVEN** macOS reports reserved menu-bar space at the top of a screen
- **WHEN** the overlay is rendered on that screen
- **THEN** the top border is drawn immediately below the reserved menu-bar space
- **AND** no fixed top inset is applied to screens without reserved menu-bar space

### Requirement: Screen overlays do not intercept interaction

Screen identification overlays SHALL NOT become key or main windows, steal focus from the workspace grid, or intercept pointer events.

#### Scenario: User interacts through an overlay

- **WHEN** the user moves or clicks the pointer over a screen identification overlay
- **THEN** the overlay does not receive or block the pointer event

#### Scenario: Grid receives keyboard input

- **WHEN** screen identification overlays are visible
- **THEN** the workspace grid remains the active keyboard target

### Requirement: Screen borders minimize compositing work

GridSpaces SHALL render screen borders without allocating a full-screen transparent overlay surface.

#### Scenario: Screen borders are shown

- **WHEN** screen borders are enabled
- **THEN** GridSpaces renders only narrow opaque surfaces along the four screen edges
- **AND** does not create a display-sized alpha-composited window

### Requirement: Screen overlays follow the grid lifecycle

GridSpaces SHALL show screen identification overlays only while the workspace grid is visible and SHALL derive them from the current screens, monitor state, and appearance configuration on each open.

#### Scenario: Grid opens with cached monitor state

- **WHEN** the workspace grid opens and cached monitor ordering is available
- **THEN** the overlay helper presents overlays immediately from the cached ordering
- **AND** grid popup presentation does not wait for overlay window creation or monitor refresh

#### Scenario: Grid opens without cached monitor state

- **WHEN** the workspace grid opens before the helper has loaded monitor ordering
- **THEN** the helper presents overlays immediately using deterministic current-screen order
- **AND** updates them after a monitor-only background refresh

#### Scenario: Monitor refresh is performed

- **WHEN** visible overlays refresh their monitor ordering
- **THEN** the helper queries only AeroSpace monitor state
- **AND** does not wait for the full workspace or per-workspace window snapshot

#### Scenario: Grid closes

- **WHEN** the workspace grid closes for any reason
- **THEN** all screen identification overlays are removed

#### Scenario: Grid reopens after display topology changes

- **WHEN** the workspace grid opens after a screen was added, removed, moved, or resized
- **THEN** GridSpaces reevaluates the configured minimum against the current connected monitor count
- **AND** creates overlays for the current connected screens and their current frames only when the minimum is met
- **AND** no overlay remains for a disconnected screen

#### Scenario: Appearance configuration reloads while grid is open

- **WHEN** the appearance configuration is reloaded while the workspace grid is open
- **THEN** visible overlays update to the new enabled state, minimum monitor count, width, and monitor palette

### Requirement: Screen overlays run independently from the grid popup

GridSpaces SHALL render and manage screen overlay windows in a persistent helper process controlled by local IPC.

#### Scenario: Overlay windows are created

- **WHEN** the grid agent requests screen overlays
- **THEN** overlay window creation and drawing occur in the helper process
- **AND** the grid agent's main thread remains available to present and operate the grid popup

#### Scenario: Grid agent terminates

- **WHEN** the grid agent terminates normally
- **THEN** it requests shutdown of the overlay helper
- **AND** the helper removes its overlay windows before exiting
