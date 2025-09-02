-- ~/.config/nvim/init.lua
-- Bootstrap lazy.nvim
vim.g.maplocalleader = " "
vim.g.mapleader = " "
require("config.lazy")

-- Load the core config
require("config")

-- Load plugins
require("plugins")
