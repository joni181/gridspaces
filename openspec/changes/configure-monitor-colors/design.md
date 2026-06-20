## Context

`GridViewModel.monitorColor(for:)` currently owns a hard-coded SwiftUI palette of `.cyan`, `.orange`, `.green`, `.pink`, `.purple`, and `.yellow`. It selects a color by the monitor's index in the latest AeroSpace monitor list and wraps with modulo arithmetic. The core configuration model has no appearance section.

The configuration layer should remain independent of SwiftUI, while color parsing and validation should produce predictable results before rendering. Existing configurations must continue to load without changes.

## Goals / Non-Goals

**Goals:**

- Let users define the ordered monitor palette with six-digit RGB hex values.
- Keep the setting optional and preserve the current visual palette by default.
- Keep monitor-to-color assignment deterministic and retain the existing wrap behavior when the palette is shorter than the monitor list.
- Treat an invalid palette as a configuration validation issue without crashing.
- Document the complete public configuration contract.

**Non-Goals:**

- Configuring colors per monitor ID or monitor name.
- Supporting alpha channels, shorthand hex, named colors, gradients, or separate light/dark palettes.
- Changing how AeroSpace discovers or orders monitors.
- Guaranteeing unique colors when the configured palette contains duplicates or has fewer entries than connected monitors.

## Decisions

### Decision: Add `[appearance].monitor_colors` as an ordered string array

The TOML form will be:

```toml
[appearance]
monitor_colors = ["#32ADE6", "#FF9500", "#34C759", "#FF2D55", "#AF52DE", "#FFCC00"]
```

An ordered array matches the current palette model and scales beyond the two-monitor case without introducing monitor-specific identifiers that may be unstable.

**Alternative considered:** A map keyed by monitor ID or name. Rejected because AeroSpace monitor IDs and display names are environment-specific and can change when displays are reconnected.

### Decision: Store validated hex strings in the core configuration

`GridSpacesConfig` will gain an appearance value containing normalized `#RRGGBB` strings. Core configuration loading will validate the array, while the agent will perform the small conversion from RGB components to `SwiftUI.Color`.

This keeps UI framework types out of `GridSpacesCore` and makes configuration behavior directly testable.

**Alternative considered:** Decode directly into `SwiftUI.Color`. Rejected because it would couple the core configuration package to SwiftUI and make persistence and equality less explicit.

### Decision: Use explicit sRGB defaults matching the current semantic palette

The built-in palette will be represented as `#32ADE6`, `#FF9500`, `#34C759`, `#FF2D55`, `#AF52DE`, and `#FFCC00`, corresponding to the current cyan, orange, green, pink, purple, and yellow choices. Explicit RGB values make the documented default reproducible and configurable.

### Decision: Reject the entire configured palette if any entry is invalid

A valid palette is non-empty and every entry matches `#RRGGBB`, case-insensitively. Valid values are normalized to uppercase. If the array is empty or any value is invalid, GridSpaces emits a warning and uses the complete built-in palette.

Using one coherent fallback avoids silently mixing user colors with defaults or changing color-to-monitor positions after dropping an invalid entry.

**Alternative considered:** Ignore only invalid entries. Rejected because removing an entry shifts every subsequent monitor's color and can make a typo difficult to diagnose.

### Decision: Preserve monitor-order indexing and palette cycling

The first monitor in AeroSpace's reported monitor list uses the first configured color, the second uses the second color, and so on. If the number of monitors exceeds the palette length, selection wraps using modulo arithmetic. With one monitor or an unknown monitor ID, GridSpaces uses the first palette color.

## Risks / Trade-offs

- [Explicit RGB defaults may differ slightly from dynamic platform semantic colors in some appearances] → Use stable sRGB values that closely match the current system palette and make the result reproducible.
- [A short palette can assign the same color to multiple monitors] → Document cycling behavior and recommend at least one color per connected monitor.
- [A single invalid item discards otherwise valid custom colors] → Emit a warning that identifies the invalid setting and clearly state the full-palette fallback.

## Migration Plan

No migration is required. Existing files omit `[appearance]` and receive the built-in palette. Rollback removes the setting and restores the hard-coded palette; existing TOML files remain decodable because unknown tables are ignored.

## Open Questions

None.
