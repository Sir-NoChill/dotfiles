-- ~/.config/nvim/lua/config/init.lua
-- This file serves as the main configuration loader

local M = {}

-- Load all configuration modules
require("config.options")  -- Vim options and settings
require("config.keymaps")  -- Global key mappings  
require("config.autocmds") -- Autocommands

-- Function to reload all config modules (useful for development)
function M.reload()
  -- Clear the module cache for config modules
  for name, _ in pairs(package.loaded) do
    if name:match("^config%.") and name ~= "config.init" then
      package.loaded[name] = nil
    end
  end
  
  -- Reload modules
  require("config.options")
  require("config.keymaps")
  require("config.autocmds")
  
  vim.notify("Config reloaded!", vim.log.levels.INFO)
end

-- Make reload function globally available
vim.keymap.set("n", "<leader><leader>r", M.reload, { desc = "Reload config" })

return M
