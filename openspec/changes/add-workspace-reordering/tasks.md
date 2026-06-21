## 1. Configuration and command model

- [ ] 1.1 Replace fixed movement command identifiers with a parsed action model that supports `move-workspace <direction>` and `move-to-display <target>`
- [ ] 1.2 Add default `Alt+h/j/k/l` workspace-content bindings and retain `Shift+h/j/k/l` move-to-display defaults
- [ ] 1.3 Remove support for the old `move-left/down/up/right/next/previous` command values
- [ ] 1.4 Add parser and validation tests for canonical actions, rejected old values, collisions, malformed arguments, and custom modifier combinations

## 2. Grid destination resolution

- [ ] 2.1 Add non-wrapping directional destination lookup for configured workspace tiles that skips blank cells
- [ ] 2.2 Make overflow workspaces ineligible as workspace-reorder sources and destinations
- [ ] 2.3 Add grid-model tests for occupied, empty, gapped, edge, and overflow cases

## 3. AeroSpace workspace-content exchange

- [ ] 3.1 Add an AeroSpace client method to move a specified window ID to a workspace with `move-node-to-workspace --window-id`
- [ ] 3.2 Implement fresh source/destination window snapshots and serial exchange of the two ID sets without a temporary workspace
- [ ] 3.3 Re-query and verify final membership of all surviving snapshotted windows
- [ ] 3.4 Implement best-effort membership rollback to original workspaces after partial failure
- [ ] 3.5 Add tests using an injectable/fake AeroSpace command runner for empty moves, occupied swaps, command failure, vanished windows, and verification failure

## 4. In-grid action behavior

- [ ] 4.1 Add a serialized/busy workspace-reorder action to `GridViewModel`
- [ ] 4.2 Dispatch configured `move-workspace` and `move-to-display` actions separately in `PanelController`
- [ ] 4.3 On success, refresh state and move the highlight to the destination while keeping the popup open
- [ ] 4.4 On failure, refresh state, retain the source highlight, and present the error
- [ ] 4.5 Add view-model tests for highlight movement, no-op boundaries, busy input suppression, success, and rollback errors

## 5. Modifier move-mode visualization

- [ ] 5.1 Derive a common non-empty modifier set from the four configured workspace-movement bindings
- [ ] 5.2 Observe local `flagsChanged` events while the popup is key and compare relevant modifiers exactly
- [ ] 5.3 Add a subtle staggered shake animation to workspace tiles while move mode is indicated
- [ ] 5.4 Respect Reduce Motion with a static visual emphasis and clear modifier state when the popup resigns key or closes
- [ ] 5.5 Add tests for common modifiers, exact-match behavior, extra modifiers, mixed modifiers, unmodified bindings, and state reset

## 6. Documentation and verification

- [ ] 6.1 Update the sample config, README, configuration reference, and verification guide with both movement domains and the canonical action syntax
- [ ] 6.2 Document that window membership is preserved but exact AeroSpace tiling-tree layout is best-effort
- [ ] 6.3 Verify that no maintained documentation or checked-in config still uses the removed display-action values
- [ ] 6.4 Manually verify empty movement, occupied swapping, highlight behavior, display movement, shake activation, Reduce Motion, and a forced partial failure against a supported AeroSpace version
- [ ] 6.5 Run the full Swift test suite and strict OpenSpec validation
