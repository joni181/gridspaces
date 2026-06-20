## Why

GridSpaces currently centers its popup on the macOS main display, even when the user is working on another display. Opening the popup on the display containing the mouse pointer better matches the user's current visual context and is consistent with comparable launchers such as Raycast.

## What Changes

- Select the target display from the mouse pointer location each time the popup opens.
- Center the popup within that display's visible frame.
- Fall back deterministically to the main display if the pointer cannot be associated with a connected display.
- Keep pointer-display placement as the single default behavior; do not add a configuration flag.

## Capabilities

### New Capabilities

- `popup-placement`: Defines how GridSpaces chooses a display and positions the popup when it opens.

### Modified Capabilities

<!-- None. Popup placement is introduced as a focused capability. -->

## Impact

- `PanelController` popup positioning logic.
- AppKit screen and mouse-location APIs.
- Automated unit coverage for display selection and placement calculations.
- Manual verification on multi-display arrangements, including displays positioned left of or above the main display.
- No configuration schema, CLI surface, or AeroSpace integration changes.
