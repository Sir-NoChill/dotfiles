# Ember — Waybar

An amber-on-black firelight theme for Waybar. Floating pill clusters, a
central clock, workspace embers, and hover-reveal sliders — styled after
[cebem1nt/dotfiles](https://github.com/cebem1nt/dotfiles/tree/main/.config/waybar)
and recolored to the "lone figure before the fire" palette.

## Palette

| Role            | Hex        |
|-----------------|------------|
| Background      | `#0b0806`  |
| Deep shadow     | `#2b1a0f`  |
| Firelight core  | `#c9752b`  |
| Ember highlight | `#ffb247`  |
| Warm smoke      | `#6b4a2f`  |
| Text (parchment)| `#e7d3b1`  |
| Critical (coal) | `#ff5028`  |

Status colors "heat up": normal parchment → **ember** (warning) → **hot coal** (critical).

## Files

```
waybar/
├── config.jsonc     # layout — three pill clusters, floats at the top
├── modules.jsonc    # every module + the volume/backlight slider drawers
├── style.css        # the look (imports colors.css)
├── colors.css       # the ember palette — the one file to tweak for retheming
└── window_pill.py   # single-line active-window pill (Hyprland)
```

## Layout

```
┌──────────────────────┐   ┌──────────────┐   ┌───────────────────────────────┐
│ ● ● ● ○ ○   App title │   │ 12:07 · Fri 29│   │ ♪ Artist  󰕾 󰃠 󰤨 󰂯 CPU% MEM% 󰁹 …│
└──────────────────────┘   └──────────────┘   └───────────────────────────────┘
        LEFT                    CENTER                       RIGHT
```

- **Left** — workspaces (active = glowing ember dot) + active window.
- **Center** — clock (left-click toggles date view; right-click → tz picker).
- **Right** — media, volume, backlight, network, bluetooth, cpu, mem, battery,
  updates, the Omarchy indicators (voxtype / idle / notify / screen-record), tray.

**Interactive:** hover the volume or backlight icon and a slider slides out
(amber→ember fill). Scroll them to adjust; click volume to mute. Scroll a
workspace to switch; scroll the media title to skip tracks.

## Install

```bash
cp -r ~/Code/Software/Ricing/waybar/* ~/.config/waybar/
chmod +x ~/.config/waybar/window_pill.py
```

Waybar auto-loads `config.jsonc` (which `include`s `modules.jsonc`) and
`style.css`. If you launch Waybar with explicit flags, point it at
`~/.config/waybar/config.jsonc`. Reload with `killall -SIGUSR2 waybar` or just
restart it — `reload_style_on_change` picks up CSS edits live.

> Your existing `~/.config/waybar/config.jsonc` is a Nix/Home-Manager symlink
> (the stock Omarchy bar). Copying over it will fail on a read-only symlink —
> remove or repoint it first, or run Waybar with `-c`/`-s` flags.

## Dependencies

Uses tools already on your system: `hyprctl`, `playerctl`, `pactl`,
`waybar-module-pacman-updates`, and the `omarchy-*` helpers wired to clicks.
Needs a **Nerd Font** (you have JetBrainsMono Nerd Font) and a reasonably
recent Waybar for `pulseaudio/slider` + `backlight/slider`.

## Tuning notes

- **Retheme:** edit `colors.css` only. Every color flows from there.
- **Backlight device** is set to `intel_backlight` in `modules.jsonc` (2 spots);
  change if yours differs (`ls /sys/class/backlight/`).
- **Bar height/float:** `height` + `margin-*` in `config.jsonc`.
- **Workspace count:** `persistent-workspaces` in `modules.jsonc`.

## What changed vs. your old bar

- Text labels (`CPU`, `NET`, `BT`, …) → clean Nerd Font icons; only cpu/mem keep
  a small amber label for at-a-glance reading.
- Everything moved into three rounded, translucent floating pills.
- Volume/backlight became hover-reveal sliders instead of static readouts.
- `window_pill.py` is now single-line + ember-colored, and also looks under
  `$XDG_RUNTIME_DIR/hypr` (newer Hyprland moved the event socket there).
- Dropped the undefined `custom/update` and the `/etc/xdg/waybar/style.css`
  import so the styling is fully self-contained.
