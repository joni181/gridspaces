## 1. Restructure Configuration model

- [ ] 1.1 Replace the per-command fields on `PartialKeyBindings` with a `[String: String]` dictionary (`bindings: [String: String]?`) that maps hotkey combo → command name
- [ ] 1.2 Remove `CodingKeys` from `PartialKeyBindings` (no longer needed once it's a plain dictionary decode)
- [ ] 1.3 Keep `workspaces: [String: String]?` as a separate field on a thin wrapper struct so `[keys.workspaces]` still decodes as a TOML subtable
- [ ] 1.4 Update `KeyBindings` stored values if needed (e.g. store the hotkey string using `-` separator in `defaults`)

## 2. Update config parser merge logic

- [ ] 2.1 In `ConfigLoader.merge`, iterate `document.keys.bindings` dictionary and dispatch each command name to the correct `KeyBindings` field (replacing the current `assign` call chain)
- [ ] 2.2 Add `+`-separator detection: if a hotkey string contains `+`, skip it and append a warning of the form `"[keys] '<hotkey>': use '-' as modifier separator (e.g. '<corrected>')"`
- [ ] 2.3 Add unknown-command detection: emit a warning for any command name not in the recognized vocabulary
- [ ] 2.4 Add duplicate-hotkey detection: emit a warning if two entries resolve to the same hotkey string
- [ ] 2.5 Update `normalizeWorkspaceBindings` (or its successor) to parse hotkey strings with the same `-`-separator rules, supporting multi-modifier combos (not just single characters)

## 3. Update built-in defaults and example config

- [ ] 3.1 Update `KeyBindings.defaults` so any stored hotkey strings use `-` separator (e.g. `moveLeft: "shift-h"`)
- [ ] 3.2 Rewrite `config/gridspaces.toml` `[keys]` section to the new `hotkey = 'command'` format with `-` separators
- [ ] 3.3 Rewrite `config/gridspaces.toml` `[keys.workspaces]` section to confirm it is valid under the new parser

## 4. Update tests

- [ ] 4.1 Rewrite `parsesGridKeysAndBehavior` test fixture to use the new `hotkey = 'command'` format
- [ ] 4.2 Rewrite `invalidIndividualSettingsKeepDefaults` fixture to use new format and update assertions
- [ ] 4.3 Rewrite `workspaceBindingsRequireSingleCharacterKeysAndWorkspaceNames` — remove single-character restriction if multi-modifier workspace keys are now supported, or keep and document the constraint
- [ ] 4.4 Add test: `+`-separator binding emits warning and is skipped
- [ ] 4.5 Add test: unknown command name emits warning
- [ ] 4.6 Add test: duplicate hotkey emits warning
- [ ] 4.7 Add test: multi-modifier hotkey (e.g. `ctrl-shift-j`) is accepted and maps to correct command
- [ ] 4.8 Verify `config/gridspaces.toml` loads cleanly with zero warnings (can be a test or manual smoke test)
