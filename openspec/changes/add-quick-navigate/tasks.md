## 1. Configuration

- [x] 1.1 Add `quick_navigate_{left,down,up,right}` bindings to `KeyBindings` with `ctrl-alt-shift-h/j/k/l` defaults
- [x] 1.2 Accept `quick-navigate <direction>` command values in the `[keys]` command map
- [x] 1.3 Expose per-direction hotkey, modifier, and direction lookups on `KeyBindings`
- [x] 1.4 Make hotkey modifier/base-key parsing public on `HotkeyModifiers`
- [x] 1.5 Warn when a configured quick-navigate hotkey carries no modifier
- [x] 1.6 Add tests for defaults, parsing, order-independent matching, and the modifier-less warning

## 2. Command plumbing

- [x] 2.1 Add four quick-navigate commands to the IPC protocol with direction mapping
- [x] 2.2 Add `gridspaces quick-navigate <left|down|up|right>` to the CLI, accepting the `--direction` flag form too
- [x] 2.3 Route the commands to the panel controller in the agent
- [x] 2.4 Add IPC round-trip tests

## 3. Pre-highlighted open

- [x] 3.1 Resolve the quick-navigate destination from grid geometry as soon as the focused workspace is known
- [x] 3.2 Rebuild the cached grid model against the freshly loaded config before resolving the destination
- [x] 3.3 Keep the user's highlight when the workspace snapshot arrives mid-gesture
- [x] 3.4 Queue quick-navigate steps that arrive while the grid is still opening
- [x] 3.5 Add tests for adjacent, edge, wrap, ungridded, and overflow destinations

## 4. Held-modifier gesture

- [x] 4.1 Arm a release watch from the modifiers of the triggering hotkey
- [x] 4.2 Detect release through `flagsChanged` and through a polled hardware modifier check
- [x] 4.3 Evaluate once immediately after arming so a tapped shortcut still commits
- [x] 4.4 Navigate on quick-navigate hotkeys, navigation keys, and arrows while the modifiers are held
- [x] 4.5 Commit through the existing confirm path; hold the grid open when there is no destination or an error is shown
- [x] 4.6 Disarm on close, cancel, and resign-key

## 5. Removal of headless directional switching

- [x] 5.1 Remove `focus --direction` from the CLI and its usage text
- [x] 5.2 Remove it from the README and verification checklist
- [x] 5.3 Drop the obsolete `optimize-directional-switching` change
- [ ] 5.4 Re-point the `config-validation-errors` change at a CLI command that still exists

## 6. Documentation and verification

- [x] 6.1 Add quick-navigate to the sample config, README, and configuration reference
- [x] 6.2 Document that the AeroSpace binding and the `[keys]` entry must name the same hotkey
- [x] 6.3 Add the gesture to the verification checklist
- [ ] 6.4 Manually verify hold-and-step, tap, multi-step, cancel, and release with the panel not key against a supported AeroSpace version
- [x] 6.5 Run the full Swift test suite and a release build
