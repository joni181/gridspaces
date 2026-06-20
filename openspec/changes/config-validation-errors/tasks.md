## 1. Extend ConfigLoadResult

- [ ] 1.1 Add `errors: [String]` field to `ConfigLoadResult` alongside the existing `warnings: [String]`
- [ ] 1.2 Update `ConfigLoadResult.init(config:warnings:)` to `init(config:errors:warnings:)` and fix all call sites
- [ ] 1.3 Add a doc comment on `ConfigLoadResult` stating that a non-empty `errors` means the config was not applied and callers must not use `config`

## 2. Classify diagnostics in ConfigLoader

- [ ] 2.1 In `ConfigLoader.load()`, reclassify the TOML parse failure from a warning to an error
- [ ] 2.2 In `ConfigLoader.merge()`, reclassify "grid.rows is empty / has no workspaces" from a warning to an error
- [ ] 2.3 In `ConfigLoader.merge()`, reclassify "grid.rows contains duplicate workspace names" from a warning to an error
- [ ] 2.4 Confirm all remaining diagnostics (empty key binding string, invalid move_mode value, invalid workspace binding) stay as warnings

## 3. Update GridViewModel to preserve last-good config

- [ ] 3.1 Add `private var lastGoodConfig: GridSpacesConfig?` to `GridViewModel`
- [ ] 3.2 In `reloadConfiguration()`, if `result.errors` is non-empty: keep `lastGoodConfig` (falling back to `.defaults` on first launch) as the active config and set `errorMessage` from `result.errors`
- [ ] 3.3 In `reloadConfiguration()`, if `result.errors` is empty: update `lastGoodConfig` to the new config, apply it, and set `errorMessage` from `result.warnings` (or clear it if warnings is empty)

## 4. Update CLI

- [ ] 4.1 In `main.swift` `reload-config` handler: call `ConfigLoader.load()` before sending IPC; if `result.errors` is non-empty, print each error to stderr and throw (or exit non-zero) without sending the IPC message
- [ ] 4.2 In `main.swift` `reload-config` handler: if errors is empty but warnings is non-empty, print each warning to stderr after sending IPC
- [ ] 4.3 In `main.swift` `focus` handler: after `ConfigLoader.load()`, if `result.errors` is non-empty, print each error to stderr and throw instead of continuing

## 5. Update tests

- [ ] 5.1 Update `invalidDocumentFallsBackToDefaults` test: assert `result.errors` is non-empty (not `result.warnings`)
- [ ] 5.2 Add test: empty `grid.rows` produces errors, not warnings
- [ ] 5.3 Add test: duplicate workspace names in `grid.rows` produces errors, not warnings
- [ ] 5.4 Add test: invalid individual key binding produces warnings, not errors, and `errors` is empty
- [ ] 5.5 Add test: valid config produces empty `errors` and empty `warnings`
- [ ] 5.6 Add unit test for `GridViewModel.reloadConfiguration()`: confirm active config is unchanged when reload returns errors
- [ ] 5.7 Add unit test for `GridViewModel.reloadConfiguration()`: confirm active config is updated when reload returns warnings only
