-- Machine-specific values.
--
-- This is the ONE file to template with chezmoi (e.g. rename to
-- `machine.lua.tmpl`), so every other .lua file stays byte-identical
-- across your boxes. Everything host-dependent lives here.

return {
    -- Programs
    terminal    = "/usr/bin/ghostty",
    editor      = "nvim",
    fileManager = "thunar",
    menu        = "wofi --show drun",

    -- Keyboard
    kb_layout  = "us,ca",
    kb_options = "caps:swapescape",

    -- Devices (names differ per box; find them with `hyprctl devices`)
    kbSwitchDevice   = "sonix-usb-device",
    mouseName        = "epic-mouse-v1",
    mouseSensitivity = -0.5,
}
