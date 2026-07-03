-- Window rules.
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.window_rule({
    name  = "ignore-maximize-request",
    match = { class = ".*" }, -- `*` becomes the regex `.*`
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "xwayland-fix",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true, -- was `no_initial_focus = on`; see notes
})
