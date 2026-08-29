-- Keybindings.
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local m = require("machine")
local mainMod = "SUPER"

hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(m.terminal))
hl.bind(mainMod .. " + SHIFT + W",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",              hl.dsp.exit())
hl.bind(mainMod .. " + F",              hl.dsp.exec_cmd(m.fileManager))
hl.bind(mainMod .. " + V",              hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P",              hl.dsp.exec_cmd(m.menu))
hl.bind(mainMod .. " + ALT + P",        hl.dsp.window.pseudo()) -- dwindle
-- hl.bind(mainMod .. " + S", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + Space",          hl.dsp.exec_cmd("hyprctl switchxkblayout " .. m.kbSwitchDevice .. " next"))
hl.bind(mainMod .. " + ALT + L",        hl.dsp.exec_cmd(m.lockManager))
hl.bind(mainMod .. " + I",              hl.dsp.exec_cmd(m.systemInfo))
hl.bind(mainMod .. " + ALT + C",        hl.dsp.exec_cmd(m.colourPicker))
hl.bind(mainMod .. " + ALT + DELETE",   hl.dsp.exec_cmd(m.shutdown))

-- Move focus with mainMod + hjkl
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Workspaces: switch with mainMod + [0-9], move window with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 -> key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + C",         hl.dsp.exec_cmd("grimblast copy area"))

-- Scroll through workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mainMod + LMB/RMB drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- hyprsunset gamma stepping (bindel -> locked + repeating)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("hyprctl hyprsunset gamma -10"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("hyprctl hyprsunset gamma +10"), { locked = true, repeating = true })

-- TODO (function keys, dealing with later): volume/mute on F2-F4, media on F5-F8.
-- hl.bind("F3", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),  { locked = true, repeating = true })
-- hl.bind("F2", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),  { locked = true, repeating = true })
-- hl.bind("F4", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
-- hl.bind(mainMod .. " + ALT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
-- hl.bind("F7", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
-- hl.bind("F5", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
-- hl.bind("F6", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
-- hl.bind("F8", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
