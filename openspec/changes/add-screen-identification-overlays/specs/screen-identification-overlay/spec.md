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
- **THEN** GridSpaces displays no screen identification borders or infill

#### Scenario: Palette is shorter than the screen list

- **GIVEN** there are more connected screens than configured monitor colors
- **WHEN** GridSpaces renders screen identification overlays
- **THEN** it cycles through the monitor palette using the same monitor-order rules as workspace tile outlines

#### Scenario: Screen borders are disabled without infill

- **GIVEN** screen borders and screen infill are both disabled
- **WHEN** the workspace grid opens
- **THEN** GridSpaces displays no screen identification overlays

### Requirement: Render configurable screen borders and infill

Each screen identification overlay SHALL cover the full screen frame, draw an enabled border inward at the configured width, and draw enabled infill inside the border using the same color at the configured transparency.

#### Scenario: Default appearance is used

- **GIVEN** at least 2 monitors are connected
- **WHEN** the workspace grid opens with the default appearance configuration
- **THEN** each connected screen displays a 5-logical-pixel colored border
- **AND** no colored infill is visible

#### Scenario: Default appearance is used with one monitor

- **GIVEN** exactly 1 monitor is connected
- **WHEN** the workspace grid opens with the default appearance configuration
- **THEN** no screen identification border or infill is visible

#### Scenario: Custom border width is used

- **GIVEN** screen borders are enabled with a custom valid width
- **WHEN** the overlay is rendered
- **THEN** the complete border is visible inside the screen bounds at the configured width

#### Scenario: Infill is enabled

- **GIVEN** screen infill is enabled with a transparency below 100 percent
- **WHEN** the overlay is rendered
- **THEN** the screen area inside the border is covered by the screen's assigned monitor color
- **AND** the configured transparency is applied

#### Scenario: Infill is enabled while borders are disabled

- **GIVEN** screen infill is enabled and screen borders are disabled
- **WHEN** the workspace grid opens
- **THEN** each screen displays the configured infill without a border

### Requirement: Screen overlays do not intercept interaction

Screen identification overlays SHALL NOT become key or main windows, steal focus from the workspace grid, or intercept pointer events.

#### Scenario: User interacts through an overlay

- **WHEN** the user moves or clicks the pointer over a screen identification overlay
- **THEN** the overlay does not receive or block the pointer event

#### Scenario: Grid receives keyboard input

- **WHEN** screen identification overlays are visible
- **THEN** the workspace grid remains the active keyboard target

### Requirement: Screen overlays follow the grid lifecycle

GridSpaces SHALL show screen identification overlays only while the workspace grid is visible and SHALL derive them from the current screens, monitor state, and appearance configuration on each open.

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
- **THEN** visible overlays update to the new enabled states, minimum monitor count, width, infill, transparency, and monitor palette
