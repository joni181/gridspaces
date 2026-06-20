## 1. Shared config-opening action

- [x] 1.1 Expose the existing `PanelController` config-opening action for both popup and status-menu callers without duplicating preparation or launch logic
- [x] 1.2 Route status-menu config-open failures to the existing visible popup error surface
- [x] 1.3 Add or update tests proving all config entry points use equivalent preparation behavior

## 2. Status menu

- [x] 2.1 Add `Open Config` between `Reload Configuration` and the separator before Quit
- [x] 2.2 Assign fixed `Command+R`, `Command+,`, and `Command+Q` equivalents to reload, config-open, and quit
- [x] 2.3 Keep `Open GridSpaces` without a key equivalent and do not inspect or duplicate AeroSpace's global binding

## 3. Verification

- [x] 3.1 Run the Swift test suite and resolve regressions
- [x] 3.2 Verify all four menu items, ordering, separators, and the three fixed keyboard equivalents
- [ ] 3.3 Verify selecting or pressing each fixed menu shortcut invokes the expected action while the menu is active
- [ ] 3.4 Verify the menu `Open Config`, popup settings button, and focused `Command+,` all open the same file and preserve existing contents
