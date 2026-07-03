-- Autostart (exec-once semantics: runs only at Hyprland start).
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("LANG=C waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("dunst")
    hl.exec_cmd("hyprsunset") -- night-light daemon; gamma keybinds live in keybinds.lua
end)
