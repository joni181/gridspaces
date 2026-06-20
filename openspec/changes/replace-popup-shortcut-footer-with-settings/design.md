## Context

`GridView` currently renders a five-item shortcut legend below the workspace grid. `PanelController` installs a local key-down monitor only while the popup is visible and closes the popup when its panel resigns key status. GridSpaces already has one canonical config path: `~/.config/gridspaces/gridspaces.toml`.

The settings action crosses the SwiftUI view, AppKit keyboard handling, and filesystem/application-launch boundaries. It should behave like a standard macOS preferences shortcut without becoming another user-configurable GridSpaces binding.

## Goals / Non-Goals

**Goals:**

- Remove the persistent shortcut legend and reclaim its popup space.
- Add a discoverable settings button at the top right of the popup.
- Support both clicking the button and pressing `Command+,` while the popup is key.
- Reliably open the canonical config path, including on installations where the file has not been created yet.
- Surface an actionable error if the file cannot be prepared or opened.

**Non-Goals:**

- Adding an in-app settings editor or preferences window.
- Registering `Command+,` as a global hotkey.
- Making the settings shortcut configurable.
- Changing existing navigation, workspace, or action bindings.
- Reloading configuration automatically after the external editor saves.
- Adding a replacement legend, onboarding view, or shortcut cheat sheet elsewhere.

## Decisions

### Decision: Treat the UI cleanup and config shortcut as one change

The footer removal and settings affordance will ship together as one popup-chrome change.

- **Why:** They implement one product decision: remove persistent shortcut instruction while preserving one useful, conventional affordance. Splitting them would create unnecessary sequencing and duplicated review of the same view and keyboard event path.

### Decision: Put a clickable settings icon in the header

`GridView` will place a button using the standard settings/gear symbol at the trailing edge of the header. Its help text will read `Open Config (⌘,)`, and activating it will call a closure supplied by `PanelController`.

- **Why:** A real button provides pointer access, accessibility semantics, and a visible target. SwiftUI's help modifier provides native macOS hover help.
- **Alternative considered:** Render a decorative icon that only documents the shortcut. Rejected because a settings affordance should be operable, not merely descriptive.

### Decision: Reserve exact `Command+,` handling in the focused panel

`PanelController` will recognize comma with the Command modifier before configurable popup bindings and invoke the same action as the settings button. The local event monitor will only consume this shortcut while the panel is visible and key.

- **Why:** The existing local monitor already scopes keyboard commands to the popup lifecycle, and `windowDidResignKey` closes the popup. Handling the standard shortcut before configurable commands avoids accidental interpretation as a workspace or action key.
- **Alternative considered:** Add `Command+,` to the GridSpaces TOML keybinding model. Rejected because preferences access is conventional app chrome, and making it configurable would weaken discoverability and expand config migration/validation surface.
- **Alternative considered:** Add an app-menu Preferences command. The agent is primarily a transient popup without conventional app-menu interaction, so the visible popup control and local shortcut are the relevant surfaces.

### Decision: Open the config through `NSWorkspace`

GridSpaces will ask `NSWorkspace` to open the config URL, allowing macOS Launch Services to choose the user's associated application for TOML files.

- **Why:** This matches "default editor" behavior for a native macOS app without assuming a terminal, shell environment, or `$EDITOR` value.
- **Alternative considered:** Launch `$EDITOR`. Rejected because GUI apps commonly lack the user's interactive shell environment, terminal editors require terminal orchestration, and `$EDITOR` is not the macOS document-association default.

### Decision: Create a missing config as an empty TOML document

Before opening, GridSpaces will create `~/.config/gridspaces` if needed and atomically create an empty `gridspaces.toml` if it is absent. It will never overwrite an existing file.

- **Why:** The current loader treats a missing file as built-in defaults, and an empty TOML document has the same effective behavior. This guarantees that the requested document exists without duplicating the bundled example or serializing defaults.
- **Alternative considered:** Copy the repository's example config. Rejected because the example is not currently an executable resource and could drift from runtime defaults.
- **Alternative considered:** Fail when the file is missing. Rejected because first-time users are explicitly supported without a pre-existing config.

### Decision: Keep the popup open when launching the editor

The settings action will not explicitly close the popup. Normal focus transfer to the editor will make the panel resign key status, and the existing delegate behavior will close it.

- **Why:** This preserves the single source of truth for popup focus behavior and avoids a special-case close path. If the external launch fails and focus remains, the popup can display the error.

### Decision: Report preparation and launch failures in the popup

Filesystem errors and a rejected `NSWorkspace` open request will be converted to an actionable message on the existing popup error surface.

- **Why:** Silent failure would make both the button and shortcut appear broken. Reusing the current error presentation avoids introducing a separate alert system.

## Risks / Trade-offs

- **The user's preferred editor is not associated with `.toml` files** → `NSWorkspace` follows the system document association by design; users can change that association in macOS.
- **The config path cannot be created because of permissions or filesystem errors** → Preserve existing files, report the failing path and underlying error, and keep the popup usable.
- **The editor launch immediately transfers focus** → The popup closes through its existing resign-key behavior, which is consistent with its transient lifecycle.
- **Removing the footer reduces discoverability of other commands** → This is intentional for the pro-tool audience; workspace identifiers and the settings tooltip remain, while setup documentation continues to describe bindings.
- **An empty newly-created file offers no examples** → Empty TOML preserves defaults safely; documentation and the bundled example remain the authoritative configuration references.

## Migration Plan

No user migration is required. Remove the footer, add the header button and local shortcut, and introduce config-file preparation/opening. Rollback restores the footer and removes the settings action; any empty config file created by the action remains valid and harmless.

## Open Questions

None.
