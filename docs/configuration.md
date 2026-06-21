# Configuration Reference

GridSpaces is configured through a TOML file at:

```
~/.config/gridspaces/gridspaces.toml
```

If the file does not exist, all settings fall back to their built-in defaults. Changes take effect the next time the popup opens, or immediately when you run `gridspaces reload-config`.

---

## `[grid]`

Defines the layout of workspaces in the popup grid.

### `rows`

A 2-D array of workspace names. Each inner array is one row; each element is a workspace name (matching your AeroSpace workspaces) or an empty string for a blank cell.

Workspaces that exist in AeroSpace but are not listed here and currently have open windows appear automatically in an overflow row below the configured grid.

**Default:**
```toml
[grid]
rows = [
  ["1", "2", "3", "4", "5"],
  ["Q", "W", "E", "R", "T"],
  ["A", "S", "D", "F", "G"],
  ["Y", "X", "C", "V", "B"],
]
```

*Note:*
The default shown above represents a QWERTZ keyboard layout. If you are using QWERTY or any other layout, it is suggested to change the grid accordingly.

---

## `[appearance]`

### `monitor_colors`

An ordered array of colors used for workspace tile outlines. Each value must be a six-digit RGB hex code in `#RRGGBB` form. Hex digits are case-insensitive.

The first color is assigned to the first monitor reported by AeroSpace, the second color to the second monitor, and so on. If more monitors are connected than there are configured colors, GridSpaces cycles through the array. Configure at least one distinct color per monitor if every monitor should have a unique outline.

**Default:**

```toml
[appearance]
monitor_colors = [
  "#32ADE6", # cyan
  "#FF9500", # orange
  "#34C759", # green
  "#FF2D55", # pink
  "#AF52DE", # purple
  "#FFCC00", # yellow
]
```

The setting is optional. If it is omitted, GridSpaces uses the default palette above. If the array is empty or any entry is invalid, GridSpaces reports a configuration warning and falls back to the complete default palette.

### Screen identification overlays

When the workspace grid is open, GridSpaces can draw the monitor color around each physical screen. This makes it clear which workspace tile color corresponds to which monitor.

```toml
[appearance]
screen_borders = true
screen_border_width = 5
screen_minimum_monitors = 2
```

- `screen_borders` enables the colored screen borders. The default is `true`.
- `screen_border_width` sets the border width in logical screen pixels. It must be a positive integer and defaults to `5`.
- `screen_minimum_monitors` sets how many monitors must be connected before any screen identification overlay is shown. It must be a positive integer and defaults to `2`, so a single-monitor setup is not colored. Set it to `1` to allow overlays with one monitor.

Screen borders use the same `monitor_colors` assignment as workspace tile outlines, do not accept mouse or keyboard input, and disappear when the grid closes. Each top border is placed below any menu-bar space reserved by macOS on that specific display.

Invalid numeric values produce a configuration warning and fall back independently to their defaults. Screen infill is deferred because full-display translucent surfaces caused unacceptable compositor CPU and memory use.

---

## `[keys]`

Maps hotkey combinations to commands. The TOML key is the hotkey and the value is the command name:

```toml
[keys]
h = 'left'
shift-h = 'move-left'
```

Hotkeys follow AeroSpace's syntax: modifiers and the key are joined with `-`. Valid modifiers are `shift`, `ctrl`, `alt`, and `cmd`. Special key names: `return`, `escape`, `space`, `tab`, `delete`.

Any command not listed here falls back to its default hotkey. To disable a command entirely, omit it — there is no explicit "unbind" option.

### Navigation commands

These move the highlight within the popup grid. Pressing a navigation key does not switch workspaces; it only changes which workspace is highlighted.

| Command | Description | Default hotkey |
|---------|-------------|----------------|
| `left`  | Move the highlight one cell to the left. | `h` |
| `right` | Move the highlight one cell to the right. | `l` |
| `up`    | Move the highlight one cell up. | `k` |
| `down`  | Move the highlight one cell down. | `j` |

Navigation stops at the grid boundary unless `behavior.wrap` is enabled.

### Action commands

| Command | Description | Default hotkey |
|---------|-------------|----------------|
| `confirm` | Switch to the highlighted workspace and close the popup. | `return` |
| `cancel`  | Close the popup without switching workspaces. | `escape` |
| `close-all` | Close all windows in the highlighted workspace. Asks for confirmation first unless `behavior.confirm_close_all` is `false`. | `x` |

### Workspace move commands (directional mode)

These commands move the highlighted workspace to the monitor in a given direction. They only have an effect when more than one monitor is connected. See `behavior.move_mode`.

| Command | Description | Default hotkey |
|---------|-------------|----------------|
| `move-left`  | Move the highlighted workspace to the monitor to the left. | `shift-h` |
| `move-right` | Move the highlighted workspace to the monitor to the right. | `shift-l` |
| `move-up`    | Move the highlighted workspace to the monitor above. | `shift-k` |
| `move-down`  | Move the highlighted workspace to the monitor below. | `shift-j` |

### Workspace move commands (cycle mode)

These commands are active when `behavior.move_mode = "cycle"`. Instead of a spatial direction, they cycle the highlighted workspace through monitors in order.

| Command | Description | Default hotkey |
|---------|-------------|----------------|
| `move-next`     | Move the highlighted workspace to the next monitor. | `shift-l` |
| `move-previous` | Move the highlighted workspace to the previous monitor. | `shift-h` |

> **Note:** `move-next` and `move-previous` share their default hotkeys with `move-right` and `move-left`. Only the commands that match the active `move_mode` are used, so there is no actual conflict.

---

## `[keys.workspaces]`

Maps hotkeys directly to workspace names. Pressing a configured hotkey immediately switches to that workspace and closes the popup, without needing to navigate and confirm.

```toml
[keys.workspaces]
1 = '1'
q = 'Q'
shift-1 = 'workspace-1'
```

The TOML key is the hotkey (same syntax as `[keys]`); the value is the exact workspace name as defined in AeroSpace.

There are no built-in defaults for workspace bindings — the section is empty unless you configure it.

---

## `[behavior]`

### `wrap`

Whether grid navigation wraps around at the edges. When `true`, moving left from the leftmost column jumps to the rightmost column in the same row, and so on.

**Default:** `false`

```toml
wrap = false
```

### `confirm_close_all`

Whether the `close-all` command shows a confirmation prompt before closing windows. When `false`, windows are closed immediately without asking.

**Default:** `true`

```toml
confirm_close_all = true
```

### `move_mode`

Controls how the workspace move commands behave when more than one monitor is connected.

| Value | Behaviour |
|-------|-----------|
| `"directional"` | `move-left`, `move-right`, `move-up`, `move-down` send the workspace to the monitor in that spatial direction. |
| `"cycle"` | `move-next` and `move-previous` cycle the workspace through monitors in order. |

**Default:** `"directional"`

```toml
move_mode = "directional"
```

### `monitor_wrap`

In `"directional"` move mode, whether workspace movement wraps from the last monitor back to the first (and vice versa). Has no effect in `"cycle"` mode, which always wraps.

**Default:** `false`

```toml
monitor_wrap = false
```
