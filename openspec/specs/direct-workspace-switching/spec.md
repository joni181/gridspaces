# direct-workspace-switching Specification

## Purpose
TBD - created by archiving change add-workspace-grid. Update Purpose after archive.
## Requirements
### Requirement: Direct workspace switching from the grid

While the grid is open, GridSpaces SHALL allow an unmodified keypress to switch directly to the workspace assigned to that key in `gridspaces.toml`. A successful direct switch SHALL focus the target workspace through AeroSpace and immediately close the grid.

#### Scenario: Switching directly to a workspace

- **GIVEN** the direct-switch key `w` is assigned to workspace `W`
- **WHEN** the grid is open on workspace `5` and the user presses `w`
- **THEN** GridSpaces focuses workspace `W` and closes the grid

#### Scenario: Direct switch to the already focused workspace

- **GIVEN** a direct-switch key is assigned to the currently focused workspace
- **WHEN** the user presses that key while the grid is open
- **THEN** the focused workspace remains unchanged and the grid closes

### Requirement: Direct-switch bindings are configurable

Direct workspace bindings SHALL be declared in the `[keys.workspaces]` table in `~/.config/gridspaces/gridspaces.toml`, mapping each unmodified single-character shortcut key to its target workspace name. GridSpaces SHALL NOT infer direct-switch bindings from workspace names or grid positions.

#### Scenario: Declaring direct-switch bindings

- **WHEN** the configuration contains:

  ```toml
  [keys.workspaces]
  "1" = "1"
  "q" = "Q"
  "w" = "W"
  ```

- **THEN** pressing `1`, `q`, or `w` while the grid is open directly switches to
  workspace `1`, `Q`, or `W`, respectively

#### Scenario: Workspace has no direct-switch binding

- **WHEN** a workspace has no entry in `[keys.workspaces]`
- **THEN** it remains selectable through highlight navigation followed by the
  confirm action

#### Scenario: Multi-character workspace name

- **WHEN** a workspace has a multi-character name and no direct-switch binding
- **THEN** it remains selectable through highlight navigation followed by the
  confirm action

### Requirement: In-grid shortcuts are case-insensitive

GridSpaces SHALL compare all character-based in-grid shortcuts case-insensitively, including direct workspace bindings, navigation bindings, and action bindings.

#### Scenario: Direct-switch key is configured with different letter case

- **GIVEN** the direct-switch key is configured as either `w` or `W` and assigned to workspace `W`
- **WHEN** the user presses the unmodified `w` key
- **THEN** GridSpaces focuses workspace `W` and closes the grid

#### Scenario: Configured action key uses different letter case

- **GIVEN** a navigation or action binding is configured with a letter
- **WHEN** the user presses that letter in either case with the binding's
  required modifiers
- **THEN** GridSpaces invokes the configured navigation or action

### Requirement: Direct switching requires an unmodified keypress

A direct workspace binding SHALL match only when its key is pressed without Command, Control, Option, Shift, or Function modifiers.

#### Scenario: Modified key does not trigger direct switching

- **GIVEN** the unmodified key `w` is assigned to workspace `W`
- **WHEN** the user presses `Shift+w`, `Control+w`, `Option+w`, or `Command+w`
- **THEN** the direct switch to workspace `W` is not triggered

### Requirement: Navigation and action bindings take precedence

If a keypress matches both a direct workspace binding and an in-grid navigation or action binding, GridSpaces SHALL invoke the navigation or action binding and SHALL NOT directly switch workspaces.

#### Scenario: Direct-switch binding collides with navigation

- **GIVEN** `h` is configured both as the navigate-left key and as a direct
  binding to workspace `H`
- **WHEN** the user presses `h` while the grid is open
- **THEN** the highlight moves left, the focused workspace does not change, and
  the grid remains open

#### Scenario: Direct-switch binding collides with an action

- **GIVEN** `x` is configured both as the close-all action and as a direct
  workspace binding
- **WHEN** the user presses `x` while the grid is open
- **THEN** GridSpaces invokes the close-all action and does not directly switch
  workspaces

