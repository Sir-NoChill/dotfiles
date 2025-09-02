-- ~/.config/nvim/lua/plugins/toggleterm.lua
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      size = 20,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "curved",
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
    })

    function _G.set_terminal_keymaps()
      local opts = { buffer = 0 }
      vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
      vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
      vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
      vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
      vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
      vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
    end

    -- If you only want these mappings for toggle term use term://*toggleterm#* instead
    vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

    local Terminal = require("toggleterm.terminal").Terminal
    local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })

    function _LAZYGIT_TOGGLE()
      lazygit:toggle()
    end

    local node = Terminal:new({ cmd = "node", hidden = true })

    function _NODE_TOGGLE()
      node:toggle()
    end

    local ncdu = Terminal:new({ cmd = "ncdu", hidden = true })

    function _NCDU_TOGGLE()
      ncdu:toggle()
    end

    local htop = Terminal:new({ cmd = "htop", hidden = true })

    function _HTOP_TOGGLE()
      htop:toggle()
    end

    local python = Terminal:new({ cmd = "python", hidden = true })

    function _PYTHON_TOGGLE()
      python:toggle()
    end

    -- Set keymaps
    local keymap = vim.keymap

    keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Toggle floating terminal" })
    keymap.set("n", "<leader>th", "<cmd>ToggleTerm size=10 direction=horizontal<cr>", { desc = "Toggle horizontal terminal" })
    keymap.set("n", "<leader>tv", "<cmd>ToggleTerm size=80 direction=vertical<cr>", { desc = "Toggle vertical terminal" })
    keymap.set("n", "<leader>tn", "<cmd>lua _NODE_TOGGLE()<cr>", { desc = "Toggle node terminal" })
    keymap.set("n", "<leader>tu", "<cmd>lua _NCDU_TOGGLE()<cr>", { desc = "Toggle NCDU terminal" })
    keymap.set("n", "<leader>tt", "<cmd>lua _HTOP_TOGGLE()<cr>", { desc = "Toggle htop terminal" })
    keymap.set("n", "<leader>tp", "<cmd>lua _PYTHON_TOGGLE()<cr>", { desc = "Toggle python terminal" })
    keymap.set("n", "<leader>tl", "<cmd>lua _LAZYGIT_TOGGLE()<cr>", { desc = "Toggle lazygit terminal" })
  end,
}
