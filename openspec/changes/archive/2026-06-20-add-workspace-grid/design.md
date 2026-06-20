## Context

AeroSpace is a Swift tiling window manager for macOS with a CLI and a config-driven binding system, but no workspace overview. GridSpaces adds a keyboard-driven grid overview on top of AeroSpace without modifying it.

Constraints discovered from the target environment:

- AeroSpace exposes everything GridSpaces needs over its CLI: `list-workspaces --all/--focused [--json]`, `list-windows --workspace <n> --json`, `list-monitors [--json]`, `workspace <n>`, `move-workspace-to-monitor`, and window-closing commands. Bindings can run arbitrary commands via `exec-and-forget`.
- AeroSpace has **no event stream** for window close/move, so push-based state is not generally available; GridSpaces reads on demand instead.
- AeroSpace workspaces are a **flat named set** (persistent workspaces + any workspace with windows). There is no native 2D topology — GridSpaces introduces it via config.
- The reference user's `persistent-workspaces` forms a keyboard-shaped grid (`1 2 3 4 5` / `Q W E R T` / `A S D F G` / `Y X C V B`), which motivates the keyboard-position layout convention.
- The reference machine currently has a single monitor, so multi-monitor features must degrade to no-ops/single color.

Stakeholders: AeroSpace users who want a fast, keyboard-first workspace overview and 2D directional switching.

## Goals / Non-Goals

**Goals:**

- A fast, lightweight popup grid overview with per-tile app icons and per-monitor outline colors.
- Keyboard-first in-grid navigation (highlight, not switch) with focus-on-close.
- A 2D topology over AeroSpace's flat workspace set, defined in a TOML config and mirroring keyboard layout.
- Headless 2D directional workspace switching, wired through AeroSpace bindings.
- Clean, source-free integration with AeroSpace via its CLI, with documented setup.
- No polling; low idle CPU/GPU/memory.

**Non-Goals:**

- Live window thumbnails (app icons only for v1; thumbnails deferred — they need Screen Recording permission + ScreenCaptureKit).
- Hiding empty workspaces (deferred toggle).
- Auto-deriving grid positions from keyboard geometry (deferred; explicit config for v1).
- A persistent event-driven daemon synchronized via AeroSpace callbacks (deferred).
- Replacing or duplicating any AeroSpace functionality.

## Decisions

### Decision: Integrate via AeroSpace CLI, no source changes

GridSpaces shells out to the `aerospace` CLI for all reads and actions.

- **Why:** Cleanest integration; reuses AeroSpace's authority over state; zero coupling to AeroSpace internals; survives AeroSpace upgrades.
- **Alternatives considered:** Reading the Accessibility API directly (duplicates AeroSpace's work, risks divergence, needs more permissions); patching AeroSpace (rejected by requirement).

### Decision: Global shortcuts via AeroSpace bindings calling the GridSpaces CLI

Open-grid and headless directional switching are triggered by AeroSpace `exec-and-forget` bindings that run `gridspaces ...`.

- **Why:** Reuses AeroSpace's hotkey engine; avoids keybinding conflicts; no native global hotkey registration; single place for users to manage global keys. Confirmed acceptable as long as AeroSpace source is untouched.
- **Alternatives considered:** Native global hotkeys in GridSpaces (conflict risk, duplicate config surface); hybrid (more moving parts).
- **In-grid keys are different:** While the grid window is key/focused, GridSpaces handles `hjkl`, arrows, direct workspace selection, confirm, cancel, and move-to-monitor **natively** in-app (not via AeroSpace), since the popup owns keyboard focus.

### Decision: Direct workspace keys use explicit config mappings

The optional `[keys.workspaces]` table maps unmodified single-character keys to workspace names. Matching is case-insensitive, and existing navigation/action bindings take precedence over collisions. A match focuses the configured workspace through AeroSpace and immediately closes the grid.

- **Why:** Explicit mappings keep keyboard behavior configurable without assuming that every workspace name is a usable shortcut. They also allow a shortcut and workspace name to differ.
- **Alternative considered:** Deriving shortcuts from workspace names or grid positions. Rejected because it creates implicit bindings and ambiguous behavior for multi-character names.

### Decision: TOML config at `~/.config/gridspaces/gridspaces.toml`

- **Why:** Mirrors AeroSpace's config style and location conventions; familiar to the target audience; ergonomic for hand-editing.
- **Alternatives considered:** JSON (less ergonomic), YAML (extra parser, whitespace pitfalls).

### Decision: Explicit 2D grid layout + overflow region (Strategy A)

The configured grid is the source of truth for positions. Workspaces with windows that are not placed in the grid appear in a **single overflow row rendered below the configured grid**; empty ungridded workspaces are hidden.

- **Why:** Predictable directions for configured workspaces; guarantees no windows are ever lost; stable layout (no jumping). A single appended row is the simplest predictable shape. Rows may be ragged with gaps; navigation skips empty cells.
- **Future extension:** make the overflow placement keyboard-layout-aware (e.g. workspace `R` sits to the right of `E`), so ungridded workspaces appear in their natural keyboard position instead of a flat row. Out of scope for v1.
- **Alternatives considered:** Auto-fill reserved cells (jumpy as workspaces come/go); strict/hidden (can make windows unreachable); auto-wrap a flat list (directions are list-order, not spatial).

### Decision: Close-all-windows requires confirmation by default

The in-grid close-all-windows action prompts for a confirmation keypress before closing, and a config toggle can disable it. Confirmation is enabled by default.

- **Why:** Closing all windows is destructive and may discard unsaved work; a single confirm keypress is a cheap safeguard while staying keyboard-first. Power users who prefer speed can disable it.
- **Alternatives considered:** Rely solely on apps' own save prompts (less safe, inconsistent across apps); always-on confirmation with no toggle (annoying for power users).

### Decision: App icons for tiles (v1)

- **Why:** Lightweight, no Screen Recording permission, fast to render. Thumbnails deferred as a later capability.

### Decision: Refresh-on-open state model, no polling

GridSpaces queries AeroSpace only when the grid opens or a command runs.

- **Why:** Lowest idle cost, simplest, no background sync; acceptable freshness because the read happens immediately before display.
- **Alternatives considered:** Event-driven daemon via AeroSpace callbacks (AeroSpace lacks close/move events; more complexity for marginal latency gains).

### Decision: Move-to-monitor is directional with four shortcuts (cycle as an option)

In-grid move uses four directional actions (left/right/up/down), each its own remappable shortcut, defaulting to `Shift+h/j/k/l` (and `Shift`+arrows) to mirror the `hjkl` navigation keys. GridSpaces uses `aerospace move-workspace-to-monitor --workspace <highlighted> (left|down|up|right)`, which targets a **specific** workspace without changing focus. A config option selects **cycle mode** (`next|prev`) as an alternative for users who prefer single-key tab-style cycling. A separate toggle controls monitor wrap-around.

- **Why:** Directional matches the physical desk layout and is the user's preferred model; four keys make each direction explicit. The `--workspace` flag moves the highlighted (non-focused) workspace while leaving focus untouched, keeping the highlight stable. Cycle mode is kept as an alternative because it pairs naturally with a single tab-style key and scales to any monitor count.
- **Fallback (only if needed):** If a future AeroSpace version drops `--workspace`, focus the highlighted workspace first, then move the focused workspace. In that case it is acceptable for focus to move (the highlight stays on the moved workspace and the grid stays open).

### Decision: Runtime/process model — resident menu-bar agent + thin CLI over IPC

A lightweight, resident menu-bar agent (`LSUIElement`, idle until invoked) plus a thin `gridspaces` CLI that signals the agent over local IPC to show/hide the grid instantly. The agent does **not** poll — it reads AeroSpace only when opening.

- **Why:** Near-instant popup open; the CLI stays a thin trigger that AeroSpace bindings call; idle cost remains negligible.
- **Alternative considered:** Cold-launch the UI on each invocation (no resident process, simpler, but slower perceived open and repeated process startup cost).

### Decision: CLI command surface (initial sketch)

The `gridspaces` CLI is the contract AeroSpace bindings depend on. Initial commands:

- `gridspaces toggle` / `gridspaces open` / `gridspaces close` — control the grid overview.
- `gridspaces focus --direction <up|down|left|right>` — headless 2D directional switch.
- `gridspaces reload-config` — reload the TOML config.

In-grid actions (navigation, close-all-windows, move-to-monitor, confirm, cancel) are handled inside the app while the grid is focused and are not part of the global CLI surface.

## Risks / Trade-offs

- **Moving a non-focused (highlighted) workspace** → resolved: `move-workspace-to-monitor` accepts `--workspace <name>`, so GridSpaces moves the highlighted workspace directly without changing focus. Fallback (focus-then-move, focus allowed to move) only if that flag is unavailable.
- **No AeroSpace event stream** → state can be stale if something changes while the grid is open. Mitigation: refresh-on-open is sufficient for v1; a manual refresh key and/or future daemon can close the gap.
- **CLI invocation latency** (spawning `aerospace` several times per open) → could slow opening. Mitigation: batch/parallelize reads, prefer `--json`, and keep the resident agent warm.
- **Closing all windows is destructive** → may discard unsaved work. Mitigation: confirmation keypress is required by default (config-toggleable), and apps' own save prompts still apply.
- **Config drift between AeroSpace `persistent-workspaces` and the GridSpaces grid** → empty configured cells for non-persistent workspaces. Mitigation: document the recommended convention to keep them aligned; reserved cells render as empty tiles regardless.
- **AeroSpace CLI output format changes across versions** → parsing breakage. Mitigation: prefer `--json`, isolate parsing in the integration layer, pin a minimum supported AeroSpace version in docs.

## Migration Plan

Greenfield project; no migration. Rollout = install the app + CLI, add the GridSpaces TOML config, and add AeroSpace bindings per the README. Removal = delete the bindings, config, and app; AeroSpace is unaffected.

## Open Questions

- None outstanding. Remaining details (exact monitor ordering for cycle mode, `--wrap-around` defaults) are minor and can be settled during implementation against a real multi-monitor setup.
