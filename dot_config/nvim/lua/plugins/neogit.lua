-- ~/.config/nvim/lua/plugins/neogit.lua
return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    local neogit = require("neogit")
    neogit.setup({
      integrations = {
        telescope = true,
        diffview = true,
      },
    })

    -- Set keymaps
    vim.keymap.set("n", "<leader>gs", "<cmd>Neogit<CR>", { desc = "Open Neogit" })
  end,
}
