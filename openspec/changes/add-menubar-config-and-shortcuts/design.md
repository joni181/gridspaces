## Context

`AppDelegate.installStatusItem()` currently creates three menu items: `Open GridSpaces`, `Reload Configuration`, and `Quit GridSpaces`. Only Quit has a key equivalent. Config opening is implemented privately in `PanelController` and is already shared by the popup settings button and focused `Command+,` handling.

The global shortcut that opens GridSpaces is not owned by GridSpaces configuration. Users define it as an AeroSpace binding that invokes the GridSpaces CLI, so the app cannot reliably know which shortcut to display for `Open GridSpaces`.

## Goals / Non-Goals

**Goals:**

- Add `Open Config` to the status menu and route it through the existing config-opening behavior.
- Assign the requested fixed equivalents to reload, config-open, and quit.
- Leave `Open GridSpaces` without a menu key equivalent.

**Non-Goals:**

- Registering a GridSpaces-owned global hotkey or event tap.
- Reading or modifying AeroSpace's configuration to discover its binding.
- Adding a GridSpaces setting that duplicates the AeroSpace open binding.
- Making the fixed menu shortcuts configurable.
- Changing the focused popup's existing `Command+,` behavior.
- Automatically reloading configuration after an external editor saves it.

## Decisions

### Decision: Leave `Open GridSpaces` without a menu key equivalent

The item will remain clickable but will use an empty AppKit key equivalent. GridSpaces will not add a parallel setting or inspect `~/.aerospace.toml`.

**Why:** AeroSpace owns the global binding, and its configuration can contain modes, aliases, command sequences, or multiple bindings. Copying the shortcut into GridSpaces would create two sources of truth, while parsing AeroSpace's file would couple GridSpaces to configuration it does not own.

**Alternative considered:** Default the menu item to `Control+Option+Space`. Rejected because that value is only an example AeroSpace binding and may not match the user's actual setup.

**Alternative considered:** Add a GridSpaces menubar shortcut setting. Rejected because users would need to manually keep it synchronized with AeroSpace.

### Decision: Use fixed AppKit equivalents for the other actions

`Reload Configuration`, `Open Config`, and `Quit GridSpaces` will use `Command+R`, `Command+,`, and `Command+Q` respectively. These are app-owned actions with conventional fixed equivalents and do not require configuration parsing.

### Decision: Share config opening through `PanelController`

`PanelController` will expose the same config-opening method used by the popup button and focused shortcut. The status-menu selector will call that method rather than duplicate `ConfigFilePreparer` and `NSWorkspace` logic.

If the action fails while the popup is closed, GridSpaces will open the popup error surface so the existing actionable error remains visible.

## Risks / Trade-offs

- [The status menu does not show the user's AeroSpace open shortcut] → Accept this limitation because GridSpaces has no authoritative way to discover it.
- [Config-open failure occurs with no popup visible] → Present the existing popup error surface instead of failing silently.

## Migration Plan

No user migration is required. Existing AeroSpace bindings remain unchanged. Rollback removes the new `Open Config` menu item and the added fixed equivalents.

## Open Questions

None.
