## Why

Directional workspace switching via `gridspaces focus --direction <d>` takes 1–2 seconds. The delay comes from the CLI spawning multiple AeroSpace subprocesses on every invocation: one to identify the focused workspace, one to list all workspaces, one to list monitors, one for the workspace-monitor mapping, one per workspace to list its windows, and one final call to switch. The grid layout rarely changes; there is no reason to re-query it from AeroSpace on every keypress.

## What Changes

- Extend the IPC protocol so the CLI can delegate a directional focus request to the running agent instead of querying AeroSpace itself.
- The agent handles the request using its cached grid model, makes at most two AeroSpace calls (get focused workspace, switch to destination), and returns immediately.
- Add a latency requirement to `global-directional-switching`: the switch SHALL complete within 300 ms under normal conditions.

## Capabilities

### New Capabilities

<!-- None. -->

### Modified Capabilities

- `global-directional-switching`: Add a responsiveness requirement capping perceived latency at 300 ms.

## Impact

- `Sources/GridSpacesCore/IPC.swift` — extend `AgentCommand` with directional focus variants.
- `Sources/GridSpacesAgent/AgentIPCReceiver.swift` — handle new focus commands and delegate to `GridViewModel`.
- `Sources/GridSpacesAgent/GridViewModel.swift` — add `focusDirectionally(_ direction:)` using cached model + minimal AeroSpace calls.
- `Sources/gridspaces/main.swift` — route `focus` through agent IPC instead of performing a full snapshot in-process.
- Tests covering IPC dispatch and the agent-side focus logic.
