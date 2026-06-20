## Context

`PanelController.open()` currently calls `NSPanel.center()`. AppKit centers the panel on the main screen, so a user invoking GridSpaces while working on another display must shift attention away from the pointer and active visual context.

macOS exposes the pointer in global screen coordinates through `NSEvent.mouseLocation`, and each connected `NSScreen` exposes its global `frame` and usable `visibleFrame`. Multi-display coordinate spaces may contain negative coordinates when a display is left of or below the main display.

## Goals / Non-Goals

**Goals:**

- Choose the display containing the mouse pointer each time the popup becomes visible.
- Center the popup in that display's visible frame.
- Handle arbitrary macOS display arrangements and provide deterministic fallback behavior.
- Keep display selection and frame calculation testable without requiring multi-display hardware.

**Non-Goals:**

- Configurable popup-placement policies.
- Remembering a previously selected display or popup position.
- Positioning relative to the focused window, menu bar, Dock, or pointer itself.
- Moving an already-visible popup as the pointer crosses displays.

## Decisions

### Decision: Sample the pointer immediately before presenting the popup

After state refresh and layout are complete, GridSpaces will read `NSEvent.mouseLocation`, resolve the containing `NSScreen`, position the panel, and then call `makeKeyAndOrderFront`.

- **Why:** The pointer location at presentation time most closely represents where the user is looking. Sampling when `open()` is initially requested could become stale while AeroSpace state is loading.
- **Alternative considered:** Capture the pointer when the open command arrives. This gives invocation-time semantics but can place the popup on a display the pointer has already left.

### Decision: Center within the target screen's visible frame

GridSpaces will calculate the panel origin from the target screen's `visibleFrame` and the panel's current frame size, rather than calling `NSPanel.center()`.

- **Why:** `visibleFrame` avoids placing content beneath the menu bar or Dock. Calculating in global coordinates naturally supports displays with negative origins.
- **Alternative considered:** Center within the full screen frame. This can produce a visually offset popup when system UI reserves part of the display.

### Decision: Fall back to the main screen, then the first available screen

If no connected screen contains the sampled pointer, GridSpaces will use `NSScreen.main`; if that is unavailable, it will use the first screen returned by `NSScreen.screens`. If no screen is available, it will retain the panel's existing position and still present it.

- **Why:** The normal path should always find a containing screen, but display reconfiguration and transient AppKit state should not prevent the popup from opening.

### Decision: Do not add a configuration flag

Pointer-display placement will be the sole placement policy.

- **Why:** It directly fixes unintuitive multi-display behavior and matches the expected interaction model. A setting would expand configuration parsing, documentation, compatibility, and test surface without a demonstrated competing workflow.
- **Future extension:** If users request fixed-display, focused-window-display, or remembered-position behavior, introduce a placement-policy enum rather than a boolean flag.

### Decision: Isolate display selection and centering calculations

Screen selection and centered-origin calculation will be implemented as small helpers whose geometry can be tested with synthetic rectangles.

- **Why:** Automated tests should cover negative coordinates, visible-frame insets, and fallback behavior without relying on the developer's physical monitor arrangement.

## Risks / Trade-offs

- **Pointer moves during state refresh** → Sampling immediately before presentation intentionally uses the latest pointer position.
- **Pointer lies on a display boundary** → Use the first screen whose frame contains the point, following the stable order supplied for that screen snapshot.
- **Display configuration changes during opening** → Resolve against one current `NSScreen.screens` snapshot and use the documented fallback chain.
- **Popup is larger than the visible frame** → Centering remains deterministic; this change does not introduce popup resizing or clamping.

## Migration Plan

No user migration is required. Replace main-screen centering with pointer-screen placement. Rollback restores the existing `NSPanel.center()` call.

## Open Questions

None.
