## 1. Configuration model and validation

- [ ] 1.1 Add an appearance configuration model with the built-in six-color hex palette and include it in `GridSpacesConfig`
- [ ] 1.2 Decode optional `[appearance].monitor_colors`, accepting and normalizing valid `#RRGGBB` values
- [ ] 1.3 Warn and fall back to the complete built-in palette for empty or invalid configured palettes
- [ ] 1.4 Add configuration tests for omitted, custom, lowercase, empty, and malformed palettes

## 2. Monitor outline rendering

- [ ] 2.1 Add a tested hex-to-SwiftUI-color conversion for validated configuration values
- [ ] 2.2 Update monitor color selection to use the configured palette in AeroSpace monitor order
- [ ] 2.3 Preserve first-color behavior for one or unknown monitors and modulo cycling for short palettes
- [ ] 2.4 Add tests covering custom color order, palette cycling, and first-color fallback

## 3. Documentation and examples

- [ ] 3.1 Add the optional `[appearance]` example to `config/gridspaces.toml`
- [ ] 3.2 Update `docs/configuration.md` with syntax, default hex values, assignment order, cycling, and invalid-value fallback

## 4. Verification

- [ ] 4.1 Run the Swift test suite and resolve regressions
- [ ] 4.2 Manually verify omitted configuration preserves the current cyan/orange monitor appearance
- [ ] 4.3 Manually verify custom colors render on the expected monitors and update after moving a workspace
