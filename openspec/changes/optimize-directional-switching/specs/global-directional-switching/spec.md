# global-directional-switching — Amendment

## Added Requirements

### Requirement: Switch completes within 300 ms under normal conditions

A directional switch SHALL be perceived as near-instant. From the moment AeroSpace invokes the GridSpaces command to the moment AeroSpace reflects the new focused workspace, the total elapsed time SHALL be under 300 ms on a machine where both AeroSpace and the GridSpaces agent are already running.

#### Scenario: Fast switch with agent running

- **WHEN** the GridSpaces agent is running and the user triggers a directional switch via an AeroSpace binding
- **THEN** AeroSpace reflects the new focused workspace within 300 ms

#### Scenario: Agent not yet running

- **WHEN** the GridSpaces agent is not running and a directional switch is triggered
- **THEN** the agent is started, the switch is performed once the agent is ready, and an error is surfaced if the agent cannot be started
- **AND** the latency target does not apply while the agent is starting for the first time

### Requirement: Directional focus is delegated to the running agent

The CLI `focus` command SHALL delegate workspace resolution and switching to the running agent via IPC rather than performing its own AeroSpace queries. The agent SHALL use its in-memory grid model to determine the destination workspace and issue at most two AeroSpace calls: one to obtain the current focused workspace and one to switch to the destination.

#### Scenario: CLI delegates to agent

- **WHEN** the CLI receives a `focus --direction <d>` invocation and the agent is running
- **THEN** the CLI sends an IPC message to the agent encoding the direction and returns without making any AeroSpace calls itself

#### Scenario: Agent resolves destination from cached model

- **WHEN** the agent receives a directional focus IPC message
- **THEN** it queries AeroSpace once for the current focused workspace, computes the destination using the in-memory grid model, and calls AeroSpace once to switch
- **AND** it does NOT re-query the full workspace list, window lists, or monitor list

#### Scenario: Focused workspace fetched fresh on every request

- **WHEN** the agent receives a directional focus IPC message
- **THEN** it fetches the current focused workspace from AeroSpace at that moment rather than using any cached value
- **AND** this ensures correctness when the user has switched workspaces via native AeroSpace shortcuts between GridSpaces interactions
