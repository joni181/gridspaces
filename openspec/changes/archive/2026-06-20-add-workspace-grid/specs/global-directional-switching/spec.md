## ADDED Requirements

### Requirement: Headless 2D directional workspace switching

GridSpaces SHALL provide a popup-free command that switches the focused workspace in one of four directions (up/down/left/right) based on the configured 2D grid topology, analogous to macOS `Ctrl+Arrow` but in two dimensions.

#### Scenario: Switching directionally without opening the grid

- **WHEN** the directional-switch command is invoked for a direction and the grid overview is not open
- **THEN** AeroSpace focus moves to the workspace that occupies the adjacent cell in that direction within the configured grid
- **AND** no popup window is shown

#### Scenario: Skipping empty cells

- **WHEN** the adjacent cell in the requested direction is empty but a workspace exists further along that direction
- **THEN** focus moves to the next non-empty workspace in that direction

### Requirement: Edge-wrap behavior is configurable

Directional switching at the grid edges SHALL wrap or stop according to the same configured wrap setting used by in-grid navigation.

#### Scenario: Wrapping enabled at an edge

- **WHEN** wrapping is enabled and the focused workspace is at an edge and the user switches past that edge
- **THEN** focus continues from the opposite edge of the same row or column

#### Scenario: Wrapping disabled at an edge

- **WHEN** wrapping is disabled and the focused workspace is at an edge and the user switches past that edge
- **THEN** the focused workspace is unchanged (no-op)

### Requirement: Switching from a workspace outside the configured grid

When the focused workspace is not placed in the configured grid (an overflow/ungridded workspace), directional switching SHALL still behave deterministically.

#### Scenario: Directional switch from an ungridded workspace

- **WHEN** the focused workspace has no position in the configured grid and a directional-switch command is invoked
- **THEN** focus moves to a deterministic grid entry point (the configured grid origin) rather than failing

### Requirement: Driven by AeroSpace bindings

The directional-switch command SHALL be invocable from AeroSpace config bindings so that it works globally without GridSpaces registering its own native global hotkeys.

#### Scenario: Invoked from an AeroSpace binding

- **WHEN** an AeroSpace binding executes the GridSpaces directional-switch command for a direction
- **THEN** GridSpaces performs the switch as if the user requested that direction
