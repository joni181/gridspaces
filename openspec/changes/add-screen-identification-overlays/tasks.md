## 1. Configuration model and validation

- [x] 1.1 Add screen border and minimum-monitor fields to the appearance configuration with defaults: borders enabled, width 5, and minimum 2 monitors
- [x] 1.2 Decode the new `[appearance]` keys and validate positive border width and minimum monitor count
- [x] 1.3 Fall back invalid numeric fields independently and emit clear configuration warnings
- [x] 1.4 Add configuration tests for omitted, custom, disabled, boundary, and invalid values

## 2. Monitor-to-screen color assignment

- [x] 2.1 Isolate monitor-to-`NSScreen` reconciliation so physical screens use the same palette indices as workspace tile outlines
- [x] 2.2 Preserve monitor-order palette cycling when there are more screens than colors
- [x] 2.3 Add tests for matched displays, deterministic fallback, palette cycling, and display topology changes

## 3. Screen overlay rendering and lifecycle

- [x] 3.1 Add a non-activating, mouse-transparent overlay window that covers a screen's full frame
- [x] 3.2 Render the configured screen border using narrow opaque edge windows
- [x] 3.3 Create overlays from fresh screen and monitor state when the grid opens and keep the popup above them
- [x] 3.4 Show overlays only when the connected monitor count meets the configured minimum
- [x] 3.5 Remove every overlay on all grid-close paths and update overlays after configuration reload
- [x] 3.6 Reevaluate and remove or create overlays when configuration reload changes the minimum-monitor condition
- [x] 3.7 Avoid creating overlay windows when borders are disabled
- [x] 3.8 Add agent tests for threshold behavior, geometry, appearance, non-interaction, update, and cleanup behavior

## 4. Documentation and examples

- [x] 4.1 Add the new default appearance keys to `config/gridspaces.toml`
- [x] 4.2 Document screen border and minimum-monitor syntax, defaults, logical-pixel units, validation, palette reuse, and the deferred infill extension in `docs/configuration.md`

## 5. Verification

- [x] 5.1 Run the Swift test suite and resolve regressions
- [ ] 5.2 Manually verify the default hides overlays with 1 monitor and shows matching 5-pixel borders with 2 or more monitors
- [ ] 5.3 Manually verify custom minimum counts, disabled borders, configuration reload, and every popup-close path
- [ ] 5.4 Manually verify overlays do not steal focus or intercept pointer input on standard and full-screen Spaces

## 6. Overlay rendering fixes

- [x] 6.1 Derive each screen's top border inset from its current frame and visible frame so menu bars do not obscure the border
- [x] 6.2 Add automated coverage for per-screen top insets
- [x] 6.3 Run debug tests, release build, and strict OpenSpec validation

## 7. Independent low-latency overlay process

- [x] 7.1 Add show, hide, reload, and shutdown IPC commands for a persistent overlay helper
- [x] 7.2 Move overlay window rendering into a reusable overlay module and helper executable
- [x] 7.3 Start and stop the helper with the main grid agent and package it in `GridSpaces.app`
- [x] 7.4 Show immediately from cached monitor ordering, with deterministic first-open fallback
- [x] 7.5 Refresh only `list-monitors --json` in the background and update visible overlays when ordering changes
- [x] 7.6 Remove overlay rendering and full-snapshot dependency from the grid popup process
- [x] 7.7 Add automated tests for IPC values, cache/fallback assignment, and helper state transitions
- [x] 7.8 Run debug tests, release build, build-script packaging, and strict OpenSpec validation

## 8. Overlay performance

- [x] 8.1 Isolate experimental work on a dedicated feature branch
- [x] 8.2 Replace full-screen transparent border windows with narrow opaque edge windows
- [x] 8.3 Remove infill from the active configuration and retain it only as a future extension
- [x] 8.4 Add geometry and surface-area tests for edge-window rendering
- [x] 8.5 Measure helper CPU and memory with visible default borders
- [x] 8.6 Keep the border feature only after confirming minimal sustained performance cost
