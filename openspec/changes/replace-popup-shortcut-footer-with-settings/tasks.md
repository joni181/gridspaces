## 1. Config opening behavior

- [ ] 1.1 Add a testable helper that resolves the canonical config URL, creates the parent directory and an empty TOML file when missing, and never overwrites an existing config
- [ ] 1.2 Add an AppKit-facing action that opens the prepared config URL through `NSWorkspace` and reports preparation or launch failures to the view model
- [ ] 1.3 Add unit tests for existing-file preservation, missing-directory creation, missing-file creation, and filesystem failure handling

## 2. Popup settings controls

- [ ] 2.1 Remove the persistent keyboard-shortcut footer from `GridView`
- [ ] 2.2 Add a trailing settings button to the popup header with a standard settings symbol, accessibility labeling, and `Open Config (⌘,)` hover help
- [ ] 2.3 Wire the settings button to the shared config-opening action

## 3. Focused keyboard shortcut

- [ ] 3.1 Recognize exact `Command+,` in `PanelController` before configurable popup bindings and route it to the shared config-opening action
- [ ] 3.2 Ensure the local event monitor handles the shortcut only while the popup is visible and key, consuming it when handled
- [ ] 3.3 Add automated tests for `Command+,` recognition, modifier rejection, precedence over configurable bindings, and inactive-window behavior

## 4. Verification

- [ ] 4.1 Run the Swift test suite and resolve regressions
- [ ] 4.2 Verify the popup has no shortcut footer and the settings control remains correctly aligned with loading, confirmation, and error header states
- [ ] 4.3 Verify the hover help, button click, and `Command+,` each open an existing config in its associated macOS application
- [ ] 4.4 Verify first-use behavior creates and opens an empty config without changing effective built-in defaults
- [ ] 4.5 Verify switching focus to the editor closes the popup through the existing resign-key behavior and a failed launch leaves an actionable error visible
