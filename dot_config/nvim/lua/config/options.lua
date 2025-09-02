-- ~/.config/nvim/lua/config/options.lua

-- Set leader keys
vim.g.mapleader = " "
-- vim.g.maplocalleader = " "

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Clipboard
opt.clipboard = "unnamedplus"

-- Sign column
opt.signcolumn = "yes:1" -- prevent diagnostic flicker

-- Appearance
opt.cursorline = true
opt.termguicolors = true
opt.colorcolumn = "80"

-- Scrolling
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Split behavior
opt.splitright = true
opt.splitbelow = true

-- Backup and swap
opt.backup = false
opt.writebackup = false
opt.swapfile = false

-- Undo
opt.undofile = true
opt.undodir = vim.fn.expand("~/.config/nvim/undo")

-- Update time
opt.updatetime = 250
opt.timeoutlen = 300

-- Mouse
opt.mouse = "a"

-- Completion
opt.completeopt = { "menu", "menuone", "noselect" }

-- File encoding
opt.fileencoding = "utf-8"

-- Command line
opt.cmdheight = 1
opt.showcmd = false
opt.ruler = false

-- Folding
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldenable = false
