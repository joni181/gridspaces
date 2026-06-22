# GridSpaces

GridSpaces is a keyboard-first, Mission Control-style workspace overview for
[AeroSpace](https://github.com/nikitabobko/AeroSpace). It adds a configurable 2D
workspace grid, application icons, directional navigation, workspace actions,
and popup-free directional switching without modifying AeroSpace.

This is the first runnable version. It supports macOS 13 or newer and AeroSpace 0.20.3-Beta or newer. It uses AeroSpace's CLI on demand and does not poll in the background.
No Screen Recording or Accessibility permission is required by GridSpaces.

## Build and run

Prerequisites:

- macOS 13+
- Xcode command-line tools with Swift 5.10+
- AeroSpace installed, running, and its `aerospace` command on `PATH`

From this repository:

```sh
./scripts/run.sh
```

That builds an ad-hoc-signed `GridSpaces.app`, starts its menu-bar agent, and opens
the grid. Build artifacts are:

```text
.build/release/GridSpaces.app
.build/release/gridspaces
```

To install for your user:

```sh
./scripts/install.sh
```

This installs the app in `~/Applications` and the CLI in `~/.local/bin`. Ensure
`~/.local/bin` is on the `PATH` inherited by AeroSpace.

## Configuration

GridSpaces reads `~/.config/gridspaces/gridspaces.toml` each time the grid opens
or configuration is reloaded. A missing or invalid setting falls back to its
built-in default and reports a warning.

```sh
mkdir -p ~/.config/gridspaces
cp config/gridspaces.toml ~/.config/gridspaces/gridspaces.toml
```

Example:

```toml
[grid]
rows = [
  ["1", "2", "3", "4", "5"],
  ["Q", "W", "E", "R", "T"],
  ["A", "S", "D", "F", "G"],
  ["Y", "X", "C", "V", "B"],
]

[keys]
h = "left"
j = "down"
k = "up"
l = "right"
return = "confirm"
escape = "cancel"
x = "close-all"
alt-h = "move-workspace left"
alt-j = "move-workspace down"
alt-k = "move-workspace up"
alt-l = "move-workspace right"
shift-h = "move-to-display left"
shift-j = "move-to-display down"
shift-k = "move-to-display up"
shift-l = "move-to-display right"

[keys.workspaces]
"1" = "1"
"2" = "2"
"3" = "3"
"4" = "4"
"5" = "5"
q = "Q"
w = "W"
e = "E"
a = "A"
s = "S"
d = "D"

[behavior]
wrap = false
confirm_close_all = true
move_mode = "directional" # or "cycle"
monitor_wrap = false
```

Use an empty string for a gap in a ragged row. Configured workspace positions are
always rendered, even when AeroSpace does not currently report them. An occupied
workspace omitted from the grid appears in a single overflow row.

Entries under `[keys.workspaces]` map unmodified, single-character keys to
workspace names. These bindings are case-insensitive and switch immediately,
closing the grid. Navigation and action bindings take precedence if a key
collides. Workspaces without a direct binding remain available through grid
navigation and `Enter`.

For stable empty tiles, keep AeroSpace's `persistent-workspaces` aligned with
the GridSpaces rows. Keyboard-shaped names such as
`1 2 3 4 5 / Q W E R T / A S D F G / Y X C V B` work particularly well.

## CLI

```text
gridspaces open
gridspaces toggle
gridspaces close
gridspaces focus --direction left|down|up|right
gridspaces reload-config
```

The resident app is an `LSUIElement` menu-bar agent. The CLI starts it when
necessary and sends local distributed notifications for instant popup control.
Directional focus commands are headless and query AeroSpace only for that command.

## AeroSpace bindings

Add bindings like these to `~/.aerospace.toml`:

```toml
[mode.main.binding]
alt-tab = 'exec-and-forget gridspaces toggle'
ctrl-alt-h = 'exec-and-forget gridspaces focus --direction left'
ctrl-alt-j = 'exec-and-forget gridspaces focus --direction down'
ctrl-alt-k = 'exec-and-forget gridspaces focus --direction up'
ctrl-alt-l = 'exec-and-forget gridspaces focus --direction right'
```

Then run `aerospace reload-config`. GridSpaces does not register global hotkeys
and requires no AeroSpace source changes.

## In-grid controls

- `h/j/k/l` or arrows: move the highlight without switching
- configured workspace keys: switch immediately and close the grid
- `Enter`: focus the highlighted workspace and close
- `Esc`: close without switching
- `x`: close all windows in the highlighted workspace; confirmation is on by default
- `Alt+h/j/k/l`: move or swap all windows in the highlighted workspace through the configured grid
- `Shift+h/j/k/l` or Shift+arrows: move the highlighted workspace to another display

Holding `Alt` with the default bindings shows workspace move mode. Exact AeroSpace
tiling-tree preservation is unavailable through its public CLI, so moved windows
retain their identities but complex layouts may be re-tiled.

With one display, move-to-display commands are no-ops and all tiles share one outline
color. In cycle mode, left/up means previous and right/down means next.

## Development

```sh
swift test
./scripts/build.sh
./scripts/measure.sh
```

See [docs/verification.md](docs/verification.md) for the manual scenario checklist.
