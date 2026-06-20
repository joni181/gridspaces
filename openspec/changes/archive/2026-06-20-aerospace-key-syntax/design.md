## Context

The current `[keys]` config maps command names to hotkey strings (`command = "hotkey"`), the opposite of AeroSpace's `hotkey = 'command'` convention. Both the direction and the modifier separator (`+` vs `-`) differ. Since gridspaces is a companion tool to AeroSpace, users configure both, and the inconsistency creates friction.

The config is parsed in `Sources/GridSpacesCore/Configuration.swift` using `TOMLDecoder` against typed Swift structs. Hotkeys are plain strings stored on `KeyBindings`; there is no runtime parsing of hotkey strings into modifier + key components (the app uses a separate `KeyEventListener` for that). The change is purely to the config shape and the string format accepted as a hotkey value.

## Goals / Non-Goals

**Goals:**
- Restructure `[keys]` so the TOML key is the hotkey combo and the value is the command name.
- Change the accepted modifier separator from `+` to `-` in hotkey strings.
- Keep `[keys.workspaces]` as a separate subtable (already hotkey-first, just needs separator update).
- Emit a helpful warning when a `+`-separator binding is found, to ease migration.
- Update built-in defaults, example config, and tests.

**Non-Goals:**
- Parsing hotkey strings into `NSEvent.ModifierFlags` / key codes at config load time (that remains the responsibility of the event layer).
- Supporting AeroSpace's full `[mode.<name>.binding]` nesting or multiple binding modes.
- Auto-migrating user config files on disk.

## Decisions

### Decision: Parse `[keys]` as `[String: String]` (hotkey → command), not typed struct fields

**Chosen:** Decode `[keys]` as a free-form dictionary `[String: String]` and resolve command names during merge.

**Alternative considered:** Keep one Swift property per command on `PartialKeyBindings`, switching each field name to be the hotkey string. Rejected because command names are not valid Swift identifiers in general (they contain hyphens), and adding a field per possible hotkey would be unworkable.

**Rationale:** A `[String: String]` dictionary is the natural model for a TOML table of arbitrary key→value pairs. The merge step validates keys against a fixed command vocabulary and builds the `KeyBindings` struct. This is the same approach AeroSpace uses (`for (binding, rawCommand) in rawTable`).

### Decision: `[keys.workspaces]` remains a separate subtable

**Chosen:** Keep `[keys.workspaces]` as a distinct TOML subtable decoded as `[String: String]` (hotkey → workspace name). This matches the current structure (already hotkey-first) and keeps workspace bindings discoverable at a glance.

**Alternative considered:** Merge workspace bindings into the main `[keys]` table using `workspace-<name> = 'hotkey'` or a similar convention. Rejected because it would make the flat `[keys]` table ambiguous and harder to document.

### Decision: Emit a warning (not a hard error) for `+`-separator strings

**Chosen:** Detect a `+` in the hotkey string, skip the binding, and emit a descriptive warning naming the corrected form.

**Rationale:** Users with existing configs should get a clear signal rather than a silent drop or a cryptic parse failure. The warning can be printed on startup alongside other config warnings.

### Decision: Command names in values use kebab-case

**Chosen:** Command names are the kebab-case identifiers already used internally (`move-left`, `close-all`, etc.), matching the Swift `CodingKeys` `rawValue` pattern and AeroSpace's command naming style.

## Risks / Trade-offs

- [Breaking change] Existing user configs with the old format will stop working silently unless the parser detects `+`-separator usage and emits a warning. → Mitigation: the `+`-detection warning and a changelog migration note.
- [Ambiguity in `[keys.workspaces]`] Hotkeys in the workspaces table previously had no modifier, so the `-` separator change has no practical impact today. If a user tries to bind a modifier+key to a workspace, the new parser will accept it. → No mitigation needed; this is an improvement.
- [No runtime key-code validation at parse time] The parser accepts any `shift-h` string without knowing whether `h` is a real key. Invalid key names will fail silently at runtime. → This matches the current behavior and is out of scope for this change.

## Migration Plan

1. Ship the new parser behind the existing config path (no feature flag needed — config file is user-local).
2. On first launch after upgrade, the warning system will surface any `+`-separator bindings.
3. Add a migration note to the release changelog: rename `[keys]` entries to `hotkey = 'command'` format and replace `+` with `-` in all hotkey strings.
4. No rollback mechanism needed: reverting the binary restores the old parser.

## Open Questions

- Should the parser also accept `[keys]` as a flat table even if the user has no `[keys.workspaces]` subtable? **Yes** — TOML allows a mix of inline keys and subtables in the same section; the decoder must handle this. Existing `TOMLDecoder` behavior with a `[String: String]` field and a nested struct should handle this naturally if workspaces is decoded separately.
