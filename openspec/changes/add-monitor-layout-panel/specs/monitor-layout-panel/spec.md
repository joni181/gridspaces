## ADDED Requirements

### Requirement: Monitor layout panel visibility and lifecycle

GridSpaces SHALL show a monitor-layout companion panel to the left of the main workspace grid panel when `appearance.show_monitor_layout_panel` is enabled and the connected monitor count is greater than or equal to `appearance.monitor_layout_minimum_monitors`.

#### Scenario: Multi-monitor setup uses the default panel

- **GIVEN** `appearance.show_monitor_layout_panel` is omitted or set to `true`
- **AND** at least two monitors are connected
- **WHEN** the workspace grid opens
- **THEN** the monitor-layout companion panel appears to the left of the main workspace grid panel

#### Scenario: Default hides the panel for one monitor

- **GIVEN** `appearance.monitor_layout_minimum_monitors` is omitted
- **AND** exactly one monitor is connected
- **WHEN** the workspace grid opens
- **THEN** the monitor-layout panel is not shown

#### Scenario: Panel is disabled explicitly

- **GIVEN** `appearance.show_monitor_layout_panel` is `false`
- **AND** multiple monitors are connected
- **WHEN** the workspace grid opens
- **THEN** the monitor-layout panel is not shown

#### Scenario: Panel closes with the grid

- **GIVEN** the monitor-layout panel is visible
- **WHEN** the workspace grid closes for any reason
- **THEN** the monitor-layout panel is removed with the grid

#### Scenario: Configuration reload changes visibility

- **GIVEN** the workspace grid is open
- **WHEN** configuration reload changes `appearance.show_monitor_layout_panel` or `appearance.monitor_layout_minimum_monitors`
- **THEN** GridSpaces updates the monitor-layout panel visibility without requiring the user to close and reopen the grid

### Requirement: Monitor layout companion panel placement and style

The monitor-layout panel SHALL use the same companion-panel pattern as the workspace tree panel. It SHALL be a separate non-activating panel, use the same distance from the main panel, remain vertically centered relative to the main panel, and match the overall GridSpaces panel style.

#### Scenario: Panel is positioned left of the main panel

- **GIVEN** the monitor-layout panel is visible
- **WHEN** the workspace grid panel is positioned
- **THEN** the monitor-layout panel is positioned to the left of the main panel
- **AND** uses the same gap from the main panel as the tree panel uses
- **AND** is vertically centered relative to the main panel

#### Scenario: Panel matches GridSpaces style

- **GIVEN** the monitor-layout panel is visible
- **WHEN** it renders
- **THEN** its material, background, titlebar treatment, and general spacing match the existing companion tree panel style

#### Scenario: Tree panel coexistence

- **GIVEN** both `appearance.show_monitor_layout_panel` and `appearance.show_tree_panel` are enabled
- **AND** both panels meet their visibility conditions
- **WHEN** the workspace grid opens
- **THEN** the monitor-layout panel remains on the left side of the main panel
- **AND** the tree panel is positioned without overlapping the monitor-layout panel, the main panel, or itself

### Requirement: Physical monitor geometry representation

The monitor-layout panel SHALL render one shape per connected physical monitor, preserving each monitor's aspect ratio, relative size, and relative position within the current macOS screen arrangement.

#### Scenario: Side-by-side monitors with different aspect ratios

- **GIVEN** two monitors are arranged side by side and have different aspect ratios
- **WHEN** the monitor-layout panel renders
- **THEN** each monitor shape preserves its own aspect ratio
- **AND** the two shapes are positioned side by side in the same order as the physical arrangement

#### Scenario: Vertically offset monitors

- **GIVEN** one monitor is physically arranged above another monitor
- **WHEN** the monitor-layout panel renders
- **THEN** the upper monitor shape appears above the lower monitor shape in the compact layout

#### Scenario: Monitors with different sizes

- **GIVEN** connected monitors have different logical frame sizes
- **WHEN** the monitor-layout panel renders
- **THEN** the monitor shapes preserve their relative sizes under one uniform scale

#### Scenario: Adjacent monitors remain visually separated

- **GIVEN** two monitors directly touch in the physical macOS screen arrangement
- **WHEN** the monitor-layout panel renders
- **THEN** the monitor shapes remain separated by a small visible gap in the compact layout

### Requirement: Monitor color assignment

Each monitor shape SHALL use the same active monitor color assigned to workspace tile outlines for that monitor. Color selection SHALL reuse the configured `appearance.monitor_colors` palette, AeroSpace monitor-order assignment, and palette cycling behavior. A single AeroSpace monitor SHALL NOT be assigned to more than one physical monitor shape during one render.

#### Scenario: Monitor shape matches workspace tile color

- **GIVEN** a workspace tile is assigned to a monitor
- **WHEN** the workspace grid and monitor-layout panel render
- **THEN** the monitor shape for that physical monitor uses the same color as the workspace tile's monitor outline

#### Scenario: More monitors than configured colors

- **GIVEN** the configured monitor palette contains fewer colors than the connected monitor list
- **WHEN** the monitor-layout panel renders
- **THEN** monitor shapes cycle through the configured palette in the same order as workspace tile outlines

#### Scenario: Monitor matching falls back deterministically

- **GIVEN** a physical monitor cannot be matched to an AeroSpace monitor by stable display metadata
- **WHEN** the monitor-layout panel renders
- **THEN** GridSpaces assigns that monitor shape a color using a deterministic fallback order
- **AND** the fallback does not change during the current render

#### Scenario: Duplicate physical screen names

- **GIVEN** multiple physical screens have the same AppKit display name
- **WHEN** the monitor-layout panel renders
- **THEN** GridSpaces does not assign the same AeroSpace monitor to all matching screen names
- **AND** each matched physical monitor shape uses its own assigned monitor color when enough AeroSpace monitors are available

### Requirement: Highlight-driven active monitor state

The monitor-layout panel SHALL visually mark the monitor assigned to the highlighted workspace as active when the highlighted workspace has a known monitor. Mouse hover SHALL NOT affect the active monitor.

#### Scenario: Highlighted workspace activates its monitor

- **GIVEN** the highlighted workspace is assigned to a known monitor
- **WHEN** the monitor-layout panel renders
- **THEN** the shape for that monitor is shown as active
- **AND** other monitor shapes are shown as inactive

#### Scenario: Keyboard navigation updates the active monitor

- **GIVEN** the highlighted workspace is assigned to one monitor
- **WHEN** the user moves the grid highlight to a workspace assigned to another monitor
- **THEN** the active monitor state moves to that workspace's monitor

#### Scenario: Hover does not update the active monitor

- **GIVEN** the pointer is over a workspace tile that is not highlighted
- **AND** that workspace is assigned to a different monitor than the highlighted workspace
- **WHEN** the monitor-layout panel renders
- **THEN** the active monitor remains the monitor assigned to the highlighted workspace

#### Scenario: Highlighted workspace has no known monitor

- **GIVEN** the highlighted workspace has no known monitor assignment
- **WHEN** the monitor-layout panel renders
- **THEN** no monitor shape is shown as active

### Requirement: Monitor layout panel is non-interactive

The monitor-layout panel SHALL provide visual context only and SHALL NOT change the highlighted workspace, focus a workspace, move a workspace, react to hover as input, or steal keyboard focus.

#### Scenario: Clicking the monitor layout

- **WHEN** the user clicks a monitor shape in the monitor-layout panel
- **THEN** the highlighted workspace remains unchanged
- **AND** no workspace action is triggered

#### Scenario: Keyboard focus remains on the grid

- **GIVEN** the monitor-layout panel is visible
- **WHEN** the user navigates with configured grid keys
- **THEN** keyboard handling remains controlled by the workspace grid popup
