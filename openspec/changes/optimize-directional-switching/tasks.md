## 1. IPC protocol

- [ ] 1.1 Add `focusLeft`, `focusRight`, `focusUp`, `focusDown` cases to `AgentCommand` with raw values `focus-left`, `focus-right`, `focus-up`, `focus-down`

## 2. Agent-side focus handling

- [ ] 2.1 Add `focusDirectionally(_ direction: Direction)` to `GridViewModel` that fetches the focused workspace fresh, computes the destination from `model`, and calls `AeroSpaceClient().focus(workspace:)`
- [ ] 2.2 Wire the four new `AgentCommand` cases in `AgentIPCReceiver` to call `GridViewModel.focusDirectionally(_:)`

## 3. CLI

- [ ] 3.1 Replace the in-process snapshot path in `main.swift focus(direction:)` with `ensureAgentRunning()` + `sendWithRetry` using the appropriate `AgentCommand`
- [ ] 3.2 Remove the now-unused `AeroSpaceClient.snapshot()` call from the `focus` code path (the snapshot itself remains for the popup)

## 4. Tests

- [ ] 4.1 Unit-test `GridViewModel.focusDirectionally(_:)` for each direction, including edge and overflow cases
- [ ] 4.2 Verify the CLI `focus` path sends the correct IPC command and does not invoke `AeroSpaceClient` directly

## 5. Verification

- [ ] 5.1 Run the Swift test suite and resolve regressions
- [ ] 5.2 Measure round-trip latency with a stopwatch or `time` to confirm it is under 300 ms on a warmed system
