-- Input + per-device config.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/

local m = require("machine")

hl.config({
    input = {
        kb_layout  = m.kb_layout,
        kb_variant = "",
        kb_model   = "",
        kb_options = m.kb_options,
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.device({
    name        = m.mouseName,
    sensitivity = m.mouseSensitivity,
})
