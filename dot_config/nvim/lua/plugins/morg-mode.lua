require("morg").setup({
    -- All options are optional. Defaults shown.
    binary = nil,           -- Path to morg binary. nil = search $PATH
    root = nil,             -- Root directory for morg files. nil = cwd
    patterns = { "*.md", "*.morg", "*.markdown" },
    auto_tangle = false,    -- Tangle on save
    auto_lint = true,       -- Lint on save (populates diagnostics)
    prefix = "<leader>m",   -- Keybinding prefix
    snippets = true,        -- Load LuaSnip snippets (if LuaSnip available)
})
