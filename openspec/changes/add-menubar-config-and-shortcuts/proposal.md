## Why

The GridSpaces status menu does not expose configuration access and gives no shortcut hints for its actions. Adding the missing action and standard menu key equivalents makes the menu complete and consistent with keyboard-oriented macOS tools such as AeroSpace.

## What Changes

- Add an `Open Config` status-menu item that uses the same config preparation and default-application opening behavior as the popup settings button and focused `Command+,` shortcut.
- Assign status-menu shortcuts:
  - `Open GridSpaces`: no shortcut, because opening GridSpaces globally remains bound through AeroSpace.
  - `Reload Configuration`: `Command+R`.
  - `Open Config`: `Command+,`.
  - `Quit GridSpaces`: `Command+Q`.
- Preserve the existing architecture in which AeroSpace owns the global shortcut for opening GridSpaces; GridSpaces does not inspect or duplicate the AeroSpace binding.

## Capabilities

### New Capabilities

- `menubar-actions`: Defines the status menu's actions, ordering, shared config-opening behavior, and keyboard equivalents.

### Modified Capabilities

<!-- None. -->

## Impact

- `Sources/GridSpacesAgent/AgentApp.swift` — status-menu construction, actions, and fixed key equivalents.
- `Sources/GridSpacesAgent/PanelController.swift` — expose or delegate the existing shared config-opening action for use outside the popup.
- Tests for status-menu construction and config-opening behavior.
