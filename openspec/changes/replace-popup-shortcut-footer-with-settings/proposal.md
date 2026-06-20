## Why

The popup currently devotes its bottom edge to a persistent shortcut legend, even though GridSpaces targets AeroSpace users who configure and learn their own keyboard workflow. Removing that visual noise and providing a conventional settings entry point makes the grid more focused while keeping configuration easy to reach.

## What Changes

- Remove the keyboard-shortcut footer from the GridSpaces popup.
- Add a settings button in the popup header, positioned at the top right.
- Show `Open Config (⌘,)` as the settings button's hover help.
- Open `~/.config/gridspaces/gridspaces.toml` in the macOS-associated default application when the settings button is clicked or `Command+,` is pressed while the popup is focused.
- Create the configuration directory and an empty, valid TOML file before opening it when the config file does not yet exist.
- Keep `Command+,` as a fixed popup command rather than a configurable or global hotkey.

## Capabilities

### New Capabilities

- `popup-settings-access`: Defines the popup's streamlined chrome and focused access to the GridSpaces configuration file.

### Modified Capabilities

<!-- None. The existing popup overview requirements do not require a shortcut footer. -->

## Impact

- `Sources/GridSpacesAgent/GridView.swift` popup header and footer layout.
- `Sources/GridSpacesAgent/PanelController.swift` focused keyboard-event handling.
- A small config-opening service or helper using `FileManager` and `NSWorkspace`.
- Automated coverage for config-file preparation and shortcut recognition.
- Manual verification of the settings button, hover help, focus scope, and default-application launch.
- No configuration schema, CLI command, AeroSpace binding, or global hotkey changes.
