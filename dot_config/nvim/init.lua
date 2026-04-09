-- ~/.config/nvim/init.lua
-- Bootstrap lazy.nvim
vim.g.maplocalleader = " "
vim.g.mapleader = " "

local hooks = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  -- Run build script after plugin's code has changed
  if name == "telescope-fzf-native.nvim" and (kind == 'install' or kind == 'update') then
    -- Append `:wait()` if you need synchronous execution
    vim.system({ 'make' }, { cwd = ev.data.path })
  end

  -- If action relies on code from the plugin (like user command or
  -- Lua code), make sure to explicitly load it first
  -- if name == 'plug-2' and kind == 'update' then
  --   if not ev.data.active then
  --     vim.cmd.packadd('plug-2')
  --   end
  --   vim.cmd('PlugTwoUpdate')
  --   require('plug2').after_update()
  -- end
end
-- If hooks need to run on install, run this before `vim.pack.add()`
-- To act on install from lockfile, run before very first `vim.pack.add()`
vim.api.nvim_create_autocmd('PackChanged', { callback = hooks })

local plugins = {
  "numToStr/Comment.nvim",
  "sindrets/diffview.nvim",
  "folke/flash.nvim",
  "lewis6991/gitsigns.nvim",
  "nvim-lualine/lualine.nvim",
  "L3MON4D3/LuaSnip",
  "NeogitOrg/neogit",
  "shortcuts/no-neck-pain.nvim",
  "windwp/nvim-autopairs",
  -- CMP
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-buffer", -- source for text in buffer
  "hrsh7th/cmp-path", -- source for file system paths
  "hrsh7th/cmp-nvim-lsp", -- source for lsp
  "hrsh7th/cmp-cmdline", -- source for command line
  "saadparwaiz1/cmp_luasnip", -- for autocompletion
  "onsails/lspkind.nvim", -- vs-code like pictograms
  ----
  "nvim-treesitter/nvim-treesitter-textobjects",
  "nvim-treesitter/nvim-treesitter",
  "nvim-tree/nvim-web-devicons",
  "benomahony/oil-git.nvim",
  "stevearc/oil.nvim",
  "nvim-lua/plenary.nvim",
  "MeanderingProgrammer/render-markdown.nvim",
  "nvim-telescope/telescope.nvim",
  "akinsho/toggleterm.nvim",
  "Exafunction/windsurf.nvim",
  "SirNoChill/morg-mode.nvim",
}

local gh = function(x) return 'https://github.com/' .. x end
local cb = function(x) return 'https://codeberg.org/' .. x end

local base_url = "https://github.com/"

-- special installers
vim.pack.add({
  "/home/stormblessed/Code/neoj",
})

vim.pack.add(vim.tbl_map(function(plugin)
  return base_url .. plugin
end, plugins))

-- Run each plugin's config file
for _, plugin in ipairs(plugins) do
  local name = plugin:match("/(.+)$")  -- extract repo name e.g. "nvim-cmp"
  name = name:gsub("%.nvim$", "")      -- strip trailing .nvim if present
  name = name:lower()
  local ok, err = pcall(require, "plugins." .. name)
  if not ok then
    vim.notify("Failed to load config for " .. name .. ": " .. err, vim.log.levels.WARN)
  end
end
-- Load plugins
-- require("plugins")

-- Load the core config
require("config")
require("lsp")
