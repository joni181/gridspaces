## 1. Configuration model and validation

- [ ] 1.1 Add screen border, minimum-monitor, and infill fields to the appearance configuration with defaults: borders enabled, width 5, minimum 2 monitors, infill disabled, and transparency 80
- [ ] 1.2 Decode the new `[appearance]` keys and validate positive border width, positive minimum monitor count, and 0-through-100 infill transparency
- [ ] 1.3 Fall back invalid numeric fields independently and emit clear configuration warnings
- [ ] 1.4 Add configuration tests for omitted, custom, disabled, boundary, and invalid values

## 2. Monitor-to-screen color assignment

- [ ] 2.1 Isolate monitor-to-`NSScreen` reconciliation so physical screens use the same palette indices as workspace tile outlines
- [ ] 2.2 Preserve monitor-order palette cycling when there are more screens than colors
- [ ] 2.3 Add tests for matched displays, deterministic fallback, palette cycling, and display topology changes

## 3. Screen overlay rendering and lifecycle

- [ ] 3.1 Add a non-activating, mouse-transparent overlay window that covers a screen's full frame
- [ ] 3.2 Render the configured inward border and optional same-color infill at the configured transparency
- [ ] 3.3 Create overlays from fresh screen and monitor state when the grid opens and keep the popup above them
- [ ] 3.4 Show overlays only when the connected monitor count meets the configured minimum
- [ ] 3.5 Remove every overlay on all grid-close paths and update overlays after configuration reload
- [ ] 3.6 Reevaluate and remove or create overlays when configuration reload changes the minimum-monitor condition
- [ ] 3.7 Avoid creating invisible overlays when both the border and infill have no visible effect
- [ ] 3.8 Add agent tests for threshold behavior, geometry, appearance, non-interaction, update, and cleanup behavior

## 4. Documentation and examples

- [ ] 4.1 Add the new default appearance keys to `config/gridspaces.toml`
- [ ] 4.2 Document screen border, minimum-monitor, and infill syntax, defaults, logical-pixel units, transparency semantics, validation, and palette reuse in `docs/configuration.md`

## 5. Verification

- [ ] 5.1 Run the Swift test suite and resolve regressions
- [ ] 5.2 Manually verify the default hides overlays with 1 monitor and shows matching 5-pixel borders with 2 or more monitors
- [ ] 5.3 Manually verify custom minimum counts, disabled borders, infill-only mode, transparency boundaries, configuration reload, and every popup-close path
- [ ] 5.4 Manually verify overlays do not steal focus or intercept pointer input on standard and full-screen Spaces
