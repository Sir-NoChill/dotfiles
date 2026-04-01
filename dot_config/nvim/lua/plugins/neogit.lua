-- ~/.config/nvim/lua/plugins/neogit.lua
local neogit = require("neogit")
neogit.setup({
  integrations = {
    telescope = true,
    diffview = true,
  },
})

-- Set keymaps
vim.keymap.set("n", "<leader>gs", "<cmd>Neogit<CR>", { desc = "Open Neogit" })
