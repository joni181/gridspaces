## Context

The `gridspaces focus --direction <d>` command is invoked from an AeroSpace binding on every directional workspace switch. Its current implementation calls `AeroSpaceClient.snapshot()`, which spawns a separate AeroSpace subprocess for each of: focused workspace, all workspaces, monitors, workspace-monitor mapping, and every individual workspace's window list. This totals **5 + N** process spawns (where N is the workspace count), followed by one more to perform the actual switch. With a typical 9-workspace grid that is 15 subprocess round-trips, explaining the observed 1–2 second latency.

The agent is a long-running process that already maintains a `GridViewModel` holding the fully-built `GridModel` in memory. The grid layout (which workspace occupies which cell) is derived from configuration and changes only when the user edits the config file. Only the focused workspace changes frequently, and that requires a single lightweight AeroSpace call.

The existing IPC channel (`CFMessagePort` at `dev.gridspaces.agent.ipc`) already carries fire-and-forget commands for `open`, `toggle`, `close`, and `reload-config`. The same channel can carry directional focus requests.

## Goals / Non-Goals

**Goals:**

- Reduce the AeroSpace subprocess count for a directional switch from 5 + N to at most 2 (get focused workspace, switch to destination).
- Keep the user-facing CLI syntax (`gridspaces focus --direction <d>`) unchanged.
- Bring perceived switch latency below 300 ms under normal conditions.

**Non-Goals:**

- Eliminating the two remaining AeroSpace calls (the focused-workspace query is necessary for correctness; the switch call is the intended action).
- Caching the focused workspace in the agent between calls (stale focus would cause wrong navigation; always fetching it fresh is the right trade-off).
- Subscribing to AeroSpace workspace-change events (not part of the public AeroSpace interface).
- Changing any other CLI command or the grid popup behavior.

## Decisions

### Decision: Encode direction in the IPC command string

`AgentCommand` will gain four new cases: `focus-left`, `focus-right`, `focus-up`, `focus-down`. This follows the existing convention of `String` raw values and requires no changes to the IPC framing layer.

**Alternative considered:** Add a separate payload field alongside the command. Rejected because the existing protocol has no payload schema and direction is fully determined by the command name; adding a structured payload would complicate both ends for no benefit.

### Decision: Agent fetches focused workspace fresh on every focus request

`GridViewModel.focusDirectionally(_:)` will call `AeroSpaceClient().focusedWorkspace()` at the time of the request rather than relying on the cached `focusedWorkspace` property.

**Why:** The cache is updated only during `refresh()`, which is triggered by grid popup opens. If the user has switched workspaces via a native AeroSpace shortcut since the last popup open, the cached value is stale. Navigation from a stale position would silently move to the wrong workspace, which is worse than the cost of one extra subprocess call.

**Trade-off:** This keeps the minimum at 2 AeroSpace calls per switch instead of 1. Given that each call takes roughly 50–100 ms, this is well within the 300 ms target.

### Decision: CLI falls back to the existing in-process path if the agent is not running

If `CFMessagePortCreateRemote` fails (agent not running), the CLI will start the agent and retry, same as `open`/`toggle`. There is no in-process fallback for focus; the agent must be running.

**Why:** The in-process path is the root cause of the slowness and should not be retained as a fallback that keeps the old behavior alive. If the agent fails to start, the CLI will surface an error.

## Risks / Trade-offs

- [Agent grid model is stale after config change] → `reload-config` already invalidates and rebuilds the model; no additional risk beyond the existing behavior.
- [Two AeroSpace calls still take ~100–200 ms] → Acceptable; the 300 ms budget is well above this. The subprocess overhead of gridspaces startup itself adds ~20–30 ms, leaving comfortable margin.
- [IPC send has no acknowledgement] → Focus is fire-and-forget, same as the existing commands. If the agent crashes between IPC receipt and the AeroSpace call, the switch silently fails. This is the same failure mode as any other command.

## Open Questions

None.
