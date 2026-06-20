## Context

`AppDelegate.installStatusItem()` currently creates three menu items: `Open GridSpaces`, `Reload Configuration`, and `Quit GridSpaces`. Only Quit has a key equivalent. Config opening is implemented privately in `PanelController` and is already shared by the popup settings button and focused `Command+,` handling.

GridSpaces hotkeys use AeroSpace-style strings such as `ctrl-alt-space`, while AppKit menu items require a base `keyEquivalent` plus `keyEquivalentModifierMask`. The configured open shortcut can change after startup, so the status menu cannot be treated as immutable.

## Goals / Non-Goals

**Goals:**

- Add `Open Config` to the status menu and route it through the existing config-opening behavior.
- Give all actionable menu items the requested keyboard equivalents.
- Make the `Open GridSpaces` equivalent configurable, defaulting to `ctrl-alt-space`.
- Update the menu equivalent after a successful configuration reload.
- Keep shortcut parsing and AppKit conversion testable outside menu construction.

**Non-Goals:**

- Registering a GridSpaces-owned global hotkey or event tap.
- Reading or modifying AeroSpace's configuration to discover its binding.
- Making reload, config-open, or quit shortcuts configurable.
- Changing the focused popup's existing `Command+,` behavior.
- Automatically reloading configuration after an external editor saves it.

## Decisions

### Decision: Add a dedicated `[menubar].open_shortcut` setting

The configuration will accept:

```toml
[menubar]
open_shortcut = "ctrl-alt-space"
```

The setting uses the same hyphen-separated modifier and key names already documented for GridSpaces bindings. If it is absent, the built-in value is `ctrl-alt-space`. If it is invalid or cannot be represented as an AppKit menu equivalent, GridSpaces reports a configuration warning and uses the default.

**Alternative considered:** Infer the shortcut from `~/.aerospace.toml`. Rejected because AeroSpace bindings can invoke arbitrary command sequences, include multiple GridSpaces bindings, and use modes; there is no single reliable open shortcut to extract.

**Alternative considered:** Add `open-gridspaces` to `[keys]`. Rejected because `[keys]` currently defines commands handled inside the focused popup, while this value configures application chrome.

### Decision: Treat shortcuts as AppKit menu key equivalents, not global registrations

Each `NSMenuItem` receives the requested key equivalent and modifier mask. `Open GridSpaces` is converted from the configured hotkey; the other three use fixed equivalents.

**Why:** The request concerns status-menu items, and GridSpaces currently delegates global shortcuts to AeroSpace. Registering a global shortcut would create a second binding owner and could conflict with the AeroSpace command users already configure.

### Decision: Centralize hotkey-to-AppKit conversion

A small pure converter will parse supported GridSpaces hotkey tokens into a base key and `NSEvent.ModifierFlags`. It will support the documented modifiers (`cmd`, `ctrl`, `alt`, `shift`) and special keys needed by the default, including `space`.

**Alternative considered:** Parse the string inline in `AppDelegate`. Rejected because validation and edge cases would be difficult to test independently.

### Decision: Share config opening through `PanelController`

`PanelController` will expose the same config-opening method used by the popup button and focused shortcut. The status-menu selector will call that method rather than duplicate `ConfigFilePreparer` and `NSWorkspace` logic.

If the action fails while the popup is closed, GridSpaces will open the popup error surface so the existing actionable error remains visible.

### Decision: Rebuild or update the dynamic menu item after config load

`AppDelegate` will retain the `Open GridSpaces` menu item and update its equivalent from the active configuration at startup and after `Reload Configuration` completes. The menu must reflect the last successfully applied configuration; a rejected reload must not replace the previous equivalent.

This behavior must compose with the pending `config-validation-errors` change, which defines last-good configuration semantics.

## Risks / Trade-offs

- [A configured shortcut cannot be represented by `NSMenuItem`] → Warn and fall back to `ctrl-alt-space`.
- [Users may interpret the displayed shortcut as a GridSpaces-owned global binding] → Document that global invocation remains configured in AeroSpace and recommend matching the two values.
- [Reload and menu refresh can diverge if configuration application has no result callback] → Make the reload path return or publish the active config before updating the menu item.
- [Config-open failure occurs with no popup visible] → Present the existing popup error surface instead of failing silently.

## Migration Plan

No user migration is required. Existing configurations receive `ctrl-alt-space` through the built-in default. Users whose AeroSpace open binding differs can add `[menubar].open_shortcut` to keep the displayed menu equivalent aligned.

Rollback removes the new menu item and configuration field; existing files containing `[menubar]` remain parseable only if unknown top-level sections are tolerated, so rollback documentation should tell users to remove that section if using an older release.

## Open Questions

None.
