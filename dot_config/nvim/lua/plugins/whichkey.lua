-- ~/.config/nvim/lua/plugins/whichkey.lua
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  config = function()
    local wk = require("which-key")

    wk.setup({
      plugins = {
        marks = true,
        registers = true,
        spelling = {
          enabled = true,
          suggestions = 20,
        },
        presets = {
          operators = false,
          motions = true,
          text_objects = true,
          windows = true,
          nav = true,
          z = true,
          g = true,
        },
      },
    })

    -- Register key mappings
    wk.add({
      { "<leader>b", group = "buffer" },
      { "<leader>c", group = "code" },
      { "<leader>e", group = "explorer" },
      { "<leader>f", group = "find" },
      { "<leader>g", group = "git" },
      { "<leader>h", group = "hunks" },
      { "<leader>r", group = "rename" },
      { "<leader>s", group = "search" },
      { "<leader>t", group = "toggle/terminal" },
      { "<leader>w", group = "workspace" },
    })
  end,
}
