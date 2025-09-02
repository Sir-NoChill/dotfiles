-- ~/.config/nvim/lua/plugins/init.lua
-- This file loads all plugin configurations

return {
  -- Core plugins that don't need separate files
  {
    "nvim-lua/plenary.nvim", -- Lua functions library
    lazy = false,
  },
  
  -- Load all other plugin configurations
  require("plugins.colorscheme"),
  require("plugins.lualine"),
  require("plugins.treesitter"),
  require("plugins.lsp"),
  require("plugins.cmp"),
  require("plugins.telescope"),
  require("plugins.nvim-tree"),
  require("plugins.toggleterm"),
  require("plugins.gitsigns"),
  require("plugins.neogit"),
  require("plugins.diffview"),
  require("plugins.comment"),
  require("plugins.autopairs"),
  require("plugins.flash"),
  require("plugins.todo-comments"),
  require("plugins.whichkey"),
  require("plugins.codeium"),
  require("plugins.orgmode"),
  require("plugins.remote"),
}
