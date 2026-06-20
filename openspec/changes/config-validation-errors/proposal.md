## Why

When a user edits their config and reloads, gridspaces silently falls back to built-in defaults on any parse or validation error. Warnings are emitted but the app keeps running as if nothing happened. This makes it hard to notice a broken config, and the `gridspaces reload-config` CLI command always exits 0 and prints "GridSpaces configuration reloaded." even when the config was rejected. Users end up confused why their changes have no effect.

## What Changes

- **BREAKING**: `ConfigLoadResult` is restructured to carry distinct `errors` (fatal, config not applied) and `warnings` (non-fatal, partial settings applied) arrays, replacing the current single `warnings` array.
- When the config contains fatal errors (TOML parse failure, invalid grid, etc.), `ConfigLoader.load()` returns those errors and the *previous* in-memory config is preserved — the app does not fall back to built-in defaults on reload.
- The agent (`GridViewModel.reloadConfiguration`) distinguishes errors from warnings: errors prevent the new config from being applied and display prominently; warnings are shown alongside the newly-applied config.
- The CLI `reload-config` command validates the config file locally before sending the IPC message, exits non-zero and prints errors to stderr if the config is invalid, and prints warnings (if any) when the reload succeeds.
- The CLI `focus` command treats config errors as fatal (exits non-zero) rather than silently continuing with defaults.
- On first launch (no previous config), an error config still falls back to built-in defaults, since there is no "previous" good config to preserve.

## Capabilities

### New Capabilities

- `config-error-reporting`: The config loader distinguishes fatal errors from warnings. Errors prevent the config from being applied; warnings are surfaced alongside a successfully-applied config.
- `reload-preserves-last-good-config`: When a reload fails validation, the currently-active config is preserved unchanged.
- `cli-exits-nonzero-on-config-error`: The CLI exits with a non-zero status and prints actionable error messages to stderr when the config is invalid.

### Modified Capabilities

<!-- none — no existing specs to delta against -->

## Impact

- `Sources/GridSpacesCore/Configuration.swift` — `ConfigLoadResult` gains an `errors` field; `ConfigLoader.load()` must distinguish error vs. warning conditions; the merge logic must classify each diagnostic.
- `Sources/GridSpacesAgent/GridViewModel.swift` — `reloadConfiguration()` must check for errors, preserve the previous config on error, and surface errors to the UI distinctly from warnings.
- `Sources/gridspaces/main.swift` — `focus` must exit non-zero on config errors; `reload-config` should validate locally (or parse the reload result) and exit non-zero on error.
- `Tests/GridSpacesCoreTests/ConfigurationTests.swift` — tests that currently assert warnings on bad configs must be updated to assert errors instead.
