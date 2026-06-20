## 1. Configuration model

- [ ] 1.1 Add a menubar configuration model with `openShortcut` defaulting to `ctrl-alt-space`
- [ ] 1.2 Decode `[menubar].open_shortcut`, normalize supported hotkey syntax, and fall back with a warning when invalid
- [ ] 1.3 Update the bundled example and configuration documentation, including the distinction between menu equivalents and AeroSpace-managed global bindings
- [ ] 1.4 Add configuration tests for missing, custom, normalized, and invalid menubar shortcuts

## 2. Menu shortcut conversion

- [ ] 2.1 Implement a testable converter from GridSpaces hotkey strings to AppKit key equivalents and modifier masks
- [ ] 2.2 Cover `cmd`, `ctrl`, `alt`, `shift`, printable keys, and documented special keys including `space`
- [ ] 2.3 Add unit tests for valid conversions and unsupported or malformed values

## 3. Shared config-opening action

- [ ] 3.1 Expose the existing `PanelController` config-opening action for both popup and status-menu callers without duplicating preparation or launch logic
- [ ] 3.2 Route status-menu config-open failures to the existing visible popup error surface
- [ ] 3.3 Add or update tests proving all config entry points use equivalent preparation behavior

## 4. Status menu

- [ ] 4.1 Add `Open Config` between `Reload Configuration` and the separator before Quit
- [ ] 4.2 Assign fixed `Command+R`, `Command+,`, and `Command+Q` equivalents to reload, config-open, and quit
- [ ] 4.3 Assign the configured equivalent to `Open GridSpaces` at application startup
- [ ] 4.4 Update the retained `Open GridSpaces` menu item after a successful configuration reload
- [ ] 4.5 Preserve the previous menu equivalent when a reload is rejected and the last-good config remains active

## 5. Verification

- [ ] 5.1 Run the Swift test suite and resolve regressions
- [ ] 5.2 Verify all four menu items, ordering, separators, and displayed keyboard equivalents
- [ ] 5.3 Verify selecting or pressing each menu shortcut invokes the expected action while the menu is active
- [ ] 5.4 Verify changing `[menubar].open_shortcut` and reloading updates the menu without restarting
- [ ] 5.5 Verify the menu `Open Config`, popup settings button, and focused `Command+,` all open the same file and preserve existing contents
