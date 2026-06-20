# popup-placement Specification

## Purpose
TBD - created by archiving change position-popup-on-pointer-display. Update Purpose after archive.
## Requirements
### Requirement: Open the popup on the pointer display

Each time GridSpaces opens the popup, it SHALL select the connected display whose frame contains the mouse pointer at the time the popup is presented.

#### Scenario: Pointer is on a non-main display

- **GIVEN** multiple displays are connected
- **AND** the mouse pointer is within a display that is not the macOS main display
- **WHEN** the GridSpaces popup opens
- **THEN** the popup appears on the display containing the mouse pointer

#### Scenario: Pointer is on the main display

- **GIVEN** the mouse pointer is within the macOS main display
- **WHEN** the GridSpaces popup opens
- **THEN** the popup appears on the main display

#### Scenario: Pointer moves while the popup is loading

- **GIVEN** an open request is refreshing workspace state
- **AND** the pointer moves to another display before the popup is presented
- **WHEN** the popup becomes visible
- **THEN** GridSpaces selects the display containing the pointer at presentation time

#### Scenario: Popup is reopened on a different display

- **GIVEN** the popup was previously shown on one display and is now closed
- **AND** the pointer has moved to another display
- **WHEN** the popup is opened again
- **THEN** it appears on the display currently containing the pointer

### Requirement: Center the popup in the target display's visible frame

GridSpaces SHALL center the popup horizontally and vertically within the selected display's visible frame, using the display's global coordinate space.

#### Scenario: Target display has menu bar or Dock insets

- **GIVEN** the selected display's visible frame is smaller than its full frame because of the menu bar or Dock
- **WHEN** GridSpaces positions the popup
- **THEN** the popup is centered within the visible frame

#### Scenario: Target display has a negative coordinate origin

- **GIVEN** the selected display is arranged left of or below the main display and therefore has negative global coordinates
- **WHEN** GridSpaces positions the popup
- **THEN** the popup is centered correctly on that display

### Requirement: Fall back when no display contains the pointer

If no connected display frame contains the sampled pointer location, GridSpaces SHALL fall back to the macOS main display; if no main display is available, it SHALL use the first connected display. The popup SHALL still open if AppKit reports no available display.

#### Scenario: Pointer does not match a connected display

- **GIVEN** no connected display frame contains the sampled pointer location
- **AND** a main display is available
- **WHEN** the popup opens
- **THEN** GridSpaces centers the popup within the main display's visible frame

#### Scenario: Main display is unavailable

- **GIVEN** no connected display frame contains the sampled pointer location
- **AND** AppKit reports no main display
- **AND** at least one connected display is available
- **WHEN** the popup opens
- **THEN** GridSpaces centers the popup within the first available display's visible frame

#### Scenario: No display is available

- **GIVEN** AppKit transiently reports no connected display
- **WHEN** the popup opens
- **THEN** GridSpaces presents the popup without failing

### Requirement: Popup placement is not configurable

GridSpaces SHALL use pointer-display placement without requiring or exposing a popup-placement configuration setting.

#### Scenario: Existing configuration is loaded

- **GIVEN** a user has an existing valid `gridspaces.toml`
- **WHEN** this change is installed
- **THEN** no configuration migration is required
- **AND** the popup uses pointer-display placement

