## Context

`ConfigLoader.load()` currently returns `ConfigLoadResult(config:warnings:)` where `config` is always populated (defaults are substituted for every problem) and `warnings` is an array of strings. Callers have no way to distinguish "a few settings were skipped" from "the whole config is unusable". The agent's `reloadConfiguration()` just sets `errorMessage` to the joined warnings and always applies the new config. The CLI always exits 0 after a reload.

The change adds a formal error/warning distinction at the `ConfigLoadResult` layer and threads it through all three call sites: `ConfigLoader`, `GridViewModel`, and `main.swift`.

## Goals / Non-Goals

**Goals:**
- Add `errors: [String]` to `ConfigLoadResult`, keeping `warnings: [String]`.
- Classify fatal conditions (TOML parse failure, invalid/empty grid) as errors; individual-setting failures remain warnings.
- Agent: on errors, keep the previous config and display the errors.
- CLI: exit non-zero and print errors to stderr; never send IPC on a broken config.
- First-launch behavior (no prior config): errors still fall back to built-in defaults (no previous to preserve).

**Non-Goals:**
- Structured error objects (typed enums). Plain strings are sufficient and match the existing `warnings` style.
- Localized error messages.
- A diff-view of what changed between old and new config.
- Auto-healing or interactive repair of broken configs.

## Decisions

### Decision: Extend `ConfigLoadResult` rather than replacing it with `Result<ConfigLoadResult, Error>`

**Chosen:** Add `errors: [String]` to the existing `ConfigLoadResult` struct. A non-empty `errors` means the load failed; `config` on such a result is undefined (callers must not apply it — convention enforced by code review and tests, not the type system).

**Alternative considered:** Make `ConfigLoader.load()` return `Result<ConfigLoadResult, [ConfigError]>`. Rejected because it would require changes at every call site to switch on the result type, and `ConfigLoadResult` already has a warnings array that the agent and CLI display — keeping the same shape minimizes churn.

**Alternative considered:** A separate `ConfigLoadError` type with both a partial config and errors. Rejected as over-engineering for the current call sites.

### Decision: Validate config file locally in the CLI before sending IPC

**Chosen:** In `main.swift`'s `reload-config` handler, call `ConfigLoader.load()` directly, check `errors`, and only send the IPC message if there are none.

**Alternative considered:** Send IPC, have the agent respond with a success/error payload. Rejected because IPC is currently fire-and-forget (`GridSpacesIPC.send` returns `Bool`) and adding a response channel is a larger IPC refactor out of scope for this change.

**Implication:** The CLI and agent each load the config file independently during a `reload-config`. This is a double-read but is acceptable given the file is small and the latency is negligible.

### Decision: Agent holds `lastGoodConfig: GridSpacesConfig?` alongside the active config

**Chosen:** `GridViewModel` stores the last successfully-applied config. On reload error it falls back to `lastGoodConfig` (or `GridSpacesConfig.defaults` if nil, i.e. first launch).

**Alternative considered:** Store the last-good config in `PanelController` or a separate singleton. Rejected — `GridViewModel` already owns config state.

## Risks / Trade-offs

- [Double file read on `reload-config`] CLI and agent both read the config on a successful reload. → Acceptable: config file is tiny, and keeping IPC fire-and-forget avoids a larger refactor.
- [Convention, not type safety, prevents applying an error result] `ConfigLoadResult.config` is present even on error results; callers must check `errors.isEmpty` before using it. → Mitigated by a doc comment on `ConfigLoadResult` and tests that assert the agent does not apply error results.
- [Agent-side errors not surfaced to CLI] When the CLI validates successfully but the agent subsequently fails (race condition on file change), the CLI exits 0. → Rare edge case; agent already shows its own error UI. Acceptable for now.

## Migration Plan

No user-visible migration needed. The change is additive at the `ConfigLoadResult` level. Callers that only read `warnings` continue to work; they just gain access to `errors`. All callers are in-repo and will be updated in the same change.
