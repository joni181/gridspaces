## Context

GridSpaces names and positions workspaces through its configured grid. Moving the contents from workspace `B` to adjacent workspace `A` therefore behaves like changing the workspace's name/number while keeping the configured grid fixed.

AeroSpace 0.20.3-Beta exposes `list-windows --workspace <name> --json` and `move-node-to-workspace --window-id <id> <workspace>`, so GridSpaces can capture the two window-ID sets and exchange their memberships. AeroSpace does not expose a workspace rename command, a public workspace-tree export/import format, container IDs, an atomic batch command, or a command that moves a workspace root to another workspace. The open AeroSpace request for `move-node-to-workspace --root` confirms that whole-root movement is not currently available.

The popup currently observes only `keyDown` events and uses `move-left/right/up/down` for display movement. The new feature requires unambiguous action names and `flagsChanged` observation for a modifier-only visual hint.

## Goals / Non-Goals

**Goals:**

- Move a complete source window set to the nearest configured workspace tile in a requested direction.
- Swap source and destination window sets when both contain windows.
- Move into an empty destination without losing windows.
- Keep the grid open and move the highlight to the destination tile after success.
- Avoid overlapping reorder operations and attempt to restore original membership after a partial failure.
- Make workspace-content movement visually discoverable for configurations with a common modifier set.
- Disambiguate workspace-content movement from display movement.

**Non-Goals:**

- Merging two occupied workspaces.
- Renaming an AeroSpace workspace object.
- Guaranteeing preservation of AeroSpace's nested tiling tree, split ratios, or focus history.
- Reconstructing layouts with `join-with`, `move`, `layout`, or private AeroSpace state.
- Reordering overflow workspaces or moving into a blank grid cell that has no configured workspace name.
- Providing a global/headless workspace-reorder command.

## Decisions

### Decision: Exchange snapshotted window-ID sets directly

Immediately before mutation, GridSpaces will query both source and destination using `list-windows --workspace ... --json`. It will then:

1. Move every snapshotted source window to the destination.
2. Move every snapshotted destination window to the source.
3. Re-query both workspaces and verify that all surviving snapshotted IDs are assigned to the expected workspace.

No temporary workspace is needed because the destination set is identified before either set moves. Moving the source into the destination temporarily merges the sets, but the second phase addresses only the original destination IDs.

**Why:** This uses only documented public commands, works for empty and occupied destinations, and avoids inventing a temporary workspace name.

**Alternatives considered:**

- Rename or swap workspace objects: AeroSpace has no such command.
- Use a temporary workspace: functionally valid but adds naming, persistence, cleanup, and failure cases without improving layout preservation.
- Move a workspace root/container: not supported by the public CLI.

### Decision: Treat layout preservation as best-effort and do not synthesize a layout

GridSpaces will move windows in the stable order returned by the initial `list-windows` snapshots, but it will not claim to preserve nested containers, split ratios, or exact tile positions.

**Why:** Window moves preserve window identity and tiling/floating state as AeroSpace permits, but the CLI does not expose enough structural information to serialize and restore the original trees. Attempting reconstruction from screen coordinates or repeated `join-with` calls would be fragile and could produce a layout different from the source.

### Decision: Attempt membership rollback on partial failure

Only one reorder operation may run at a time. If any move or final verification fails, GridSpaces will issue best-effort compensating moves for every still-existing snapshotted window ID back to its original workspace, refresh the grid, keep the highlight at the source, and show an error.

Rollback guarantees are limited to workspace membership. It cannot restore the original tree after any successful individual move.

**Why:** AeroSpace has no transaction or batch API. Serial execution plus compensation is the strongest behavior available through the public interface.

### Decision: Use configured grid adjacency without wrapping

The destination is the nearest configured workspace tile in the requested row or column, using the same gap-skipping topology as navigation. Reordering does not wrap at grid edges, regardless of the navigation wrap setting. Overflow tiles are not valid sources or destinations.

**Why:** A workspace-content move changes state and is harder to undo mentally than navigation. Non-wrapping behavior prevents an edge keypress from unexpectedly exchanging distant workspaces. Overflow order is derived at runtime rather than configured topology, so mutating by that order would be unstable.

### Decision: Canonical action strings use a verb plus direction argument

The canonical configuration values become:

```toml
[keys]
alt-h = 'move-workspace left'
alt-j = 'move-workspace down'
alt-k = 'move-workspace up'
alt-l = 'move-workspace right'

shift-h = 'move-to-display left'
shift-j = 'move-to-display down'
shift-k = 'move-to-display up'
shift-l = 'move-to-display right'
```

`move-to-display next` and `move-to-display previous` cover cycle mode. The parser will not accept the former `move-left`, `move-down`, `move-up`, `move-right`, `move-next`, or `move-previous` values.

**Why:** Argument-style commands keep the two movement domains explicit and avoid multiplying parser identifiers for every direction. GridSpaces has not been released, so retaining compatibility aliases would add permanent parser complexity without protecting an established public interface.

### Decision: Infer the shake trigger only from a common exact modifier set

The popup will monitor local `.flagsChanged` events while it is key. It will derive a visual trigger only if all four configured `move-workspace` bindings:

- contain at least one modifier,
- contain a non-modifier key, and
- share the same modifier set.

Tiles shake only while the currently held relevant modifiers exactly equal that set. Caps Lock and device-independent non-shortcut flags are ignored. If bindings use different modifier sets or any binding is unmodified, no shake hint is shown. The shortcuts remain functional.

**Why:** This provides the requested default `Alt` affordance without adding config. Exact matching distinguishes `Alt` from `Alt+Ctrl`. Another command sharing the modifier is not a correctness problem because the shake is a hint that workspace movement is available, not an exclusive modal state.

### Decision: Highlight follows contents; AeroSpace focus does not

After a successful exchange, the highlight changes from the source workspace name to the destination workspace name. GridSpaces does not explicitly switch AeroSpace focus during the operation. A later confirm action focuses the highlighted destination as usual.

**Why:** The user explicitly asked for the highlight to follow the moved workspace. Avoiding focus commands keeps the in-grid action non-navigational and matches existing display-movement behavior.

## Risks / Trade-offs

- **Exact layout changes after individual window moves** → State the limitation in documentation; preserve stable move order; do not promise unsupported tree restoration.
- **A command fails after some windows moved** → Serialize operations, attempt membership rollback, refresh from AeroSpace, and report the partial-failure risk.
- **A window closes or is created during the exchange** → Operate on the initial snapshots; ignore vanished IDs during rollback/verification; newly created windows remain wherever AeroSpace assigned them and are not silently moved.
- **The source is the underlying focused workspace** → Do not issue focus-following commands; refresh the displayed focused marker from AeroSpace after completion.
- **Large workspaces require many subprocesses** → Run the action off the main thread, expose a busy state, and reject repeated reorder input until completion.
- **Shake animation is distracting or inaccessible** → Animate only while the exact common modifier is held, respect Reduce Motion by using a non-animated move-mode emphasis, and stop immediately on modifier release or popup close.
- **Existing development configs stop parsing old movement values** → Update the checked-in sample config and all documentation in the same change; unknown old values follow normal configuration validation behavior.

## Migration Plan

1. Add the argument-style action parser and remove the fixed old display-movement command identifiers.
2. Add the new `Alt+h/j/k/l` defaults and retain `Shift+h/j/k/l` for display movement under canonical names.
3. Update the checked-in sample config, README, configuration reference, and verification guide in the same change so no maintained example uses the removed values.
4. Treat old movement values as unknown commands through the normal configuration validation path.

Rollback consists of reverting the parser, defaults, sample config, and documentation together.

## Open Questions

- None. Exact layout-tree preservation can be revisited if AeroSpace adds a documented whole-root move or workspace rename API.
