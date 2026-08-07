## Context

GridSpaces registers no global hotkeys. AeroSpace bindings invoke the `gridspaces` CLI, which forwards a command to the resident agent over `CFMessagePort`. The grid panel is a non-activating `NSPanel` that the agent makes key, and the agent already watches `flagsChanged` while the panel is key to drive the Alt "workspace move mode" hint.

Quick-navigate needs three things the existing flow does not provide: a destination computed before the panel is shown, knowledge of which modifiers the user is holding, and a reliable signal when those modifiers are released.

## Goals / Non-Goals

Goals:

- One keypress replaces open + navigate + confirm, with further steps available while held.
- Correct highlight before the AeroSpace snapshot completes.
- Release detection that does not depend on the panel having become key.

Non-Goals:

- Registering global hotkeys inside GridSpaces. AeroSpace stays the binding owner.
- Requiring Accessibility or Input Monitoring permission.
- Preserving `focus --direction`.

## Decisions

### Where the shortcut is declared

The hotkey lives in `[keys]` alongside the in-grid bindings, as `ctrl-alt-shift-h = 'quick-navigate left'`. This is a declaration, not a registration: AeroSpace fires the binding, and GridSpaces reads the entry to learn which modifiers must stay held. The same declaration doubles as the in-grid binding, so the hotkey keeps working when the panel is key and AeroSpace does not intercept it.

Precedent: `workspaceMovementHotkeys` already declares hotkeys purely so the grid can compare held modifiers.

Per-direction modifiers are read individually rather than through `HotkeyModifiers.commonModifierSet`, which requires all four hotkeys to share one modifier set. Quick-navigate only ever needs the modifiers of the direction that was actually triggered, so mixed sets remain valid.

### Detecting release

Two complementary signals, both permission-free:

1. `flagsChanged` through the existing local event monitor — immediate, but only delivered while the panel is key.
2. A 30 ms poll of `NSEvent.modifierFlags`, which reflects hardware state regardless of key-window status.

The poll covers the two cases the monitor cannot: the panel never became key, and the modifiers were released during the window between the CLI invocation and the panel appearing. Release is defined as the held flags no longer containing every trigger modifier, so breaking the combo partially also commits.

The poll is a self-rescheduling `DispatchQueue.main.asyncAfter` chain guarded by a generation counter, matching the `openRequestID` idiom already used for superseded opens. It only runs while quick-navigate is armed.

### Tapped rather than held

A tap can release the modifiers before the panel is on screen. The evaluation runs once immediately after arming, so a tap opens the grid and commits on the next runloop turn: a brief flash, then the switch. Suppressing the panel for taps was considered and rejected — the visible grid is the feedback that the command ran, and taps and holds then behave identically.

### Destination before the snapshot

`GridViewModel.refresh` reports the focused workspace as soon as AeroSpace answers, well before the per-workspace window snapshot. Grid geometry comes from configuration alone, so the destination is resolved in that first callback against a model rebuilt from the freshly loaded config and the previously known workspace states — enough to include overflow tiles from the last open.

When the snapshot lands it must not drag the highlight back: for quick-navigate the current highlight is used as the preferred value, preserving any steps taken while loading.

Repeated presses arriving while the open is still in flight are queued and replayed after the highlight exists, so a fast double tap moves two tiles rather than one.

### Committing

Release calls the existing `confirmSelection()`, the same path as `Enter`, which focuses the highlighted workspace and closes the panel. If there is no highlight or an error is on screen, the arm is dropped and the grid stays open with normal grid keys — better than switching blind.

A quick-navigate hotkey with no modifier cannot be released. It is accepted, warned about at load, and behaves as a plain pre-highlighted open.

## Risks / Trade-offs

- A 30 ms poll runs for the lifetime of a quick-navigate gesture. Negligible, and it stops on commit, close, or disarm.
- Holding the modifiers means every keystroke carries them, so in-grid actions bound to a subset of those modifiers are unreachable during the gesture. Acceptable: the gesture is short and its purpose is switching.
- Removing `focus --direction` breaks configs that still bind it. Called out as breaking; the replacement occupies the same keys.
