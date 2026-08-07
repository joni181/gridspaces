## REMOVED Requirements

### Requirement: Headless 2D directional workspace switching

**Reason**: Superseded by `quick-navigate`. The headless command spawned 5 + N AeroSpace subprocesses per keypress and took 1–2 seconds, so it was unusable in practice; quick-navigate reaches the same destination from the resident agent and shows what it is about to do.

**Migration**: Replace `gridspaces focus --direction <d>` bindings in `~/.aerospace.toml` with `gridspaces quick-navigate <d>`.

### Requirement: Edge-wrap behavior is configurable

**Reason**: Wrap behavior for directional switching now belongs to `quick-navigate`, which shares the existing `behavior.wrap` setting with in-grid navigation.

### Requirement: Switching from a workspace outside the configured grid

**Reason**: Covered by the quick-navigate requirement that places the highlight on the grid origin when the focused workspace has no grid position.

### Requirement: Driven by AeroSpace bindings

**Reason**: Covered by the equivalent quick-navigate requirement.
