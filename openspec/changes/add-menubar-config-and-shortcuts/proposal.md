## Why

The GridSpaces status menu does not expose configuration access and gives no shortcut hints for its actions. Adding the missing action and standard menu key equivalents makes the menu complete and consistent with keyboard-oriented macOS tools such as AeroSpace.

## What Changes

- Add an `Open Config` status-menu item that uses the same config preparation and default-application opening behavior as the popup settings button and focused `Command+,` shortcut.
- Assign status-menu shortcuts:
  - `Open GridSpaces`: the configured open shortcut, defaulting to `Control+Option+Space`.
  - `Reload Configuration`: `Command+R`.
  - `Open Config`: `Command+,`.
  - `Quit GridSpaces`: `Command+Q`.
- Add a `[menubar].open_shortcut` configuration setting using GridSpaces/AeroSpace hotkey syntax, with `ctrl-alt-space` as its default.
- Refresh the `Open GridSpaces` menu item's displayed key equivalent when configuration is loaded or reloaded.
- Preserve the existing architecture in which AeroSpace owns global hotkey registration; the configured menu shortcut is a menu key equivalent and does not introduce a GridSpaces global event tap.

## Capabilities

### New Capabilities

- `menubar-actions`: Defines the status menu's actions, ordering, shared config-opening behavior, and keyboard equivalents.

### Modified Capabilities

- `configuration`: Adds the configurable status-menu shortcut for opening GridSpaces and its default/fallback behavior.

## Impact

- `Sources/GridSpacesAgent/AgentApp.swift` — status-menu construction, actions, and dynamic key-equivalent updates.
- `Sources/GridSpacesAgent/PanelController.swift` — expose or delegate the existing shared config-opening action for use outside the popup.
- `Sources/GridSpacesCore/Configuration.swift` — parse and default the new menubar shortcut setting.
- `config/gridspaces.toml` and `docs/configuration.md` — document the new setting.
- Tests for config parsing, macOS key-equivalent conversion, and menu refresh behavior.
