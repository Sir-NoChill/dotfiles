-- ~/.config/nvim/lua/plugins/diffview.lua
return {
  "sindrets/diffview.nvim",
  dependencies = "nvim-lua/plenary.nvim",
  config = function()
    require("diffview").setup({
      diff_binaries = false,
      enhanced_diff_hl = false,
      git_cmd = { "git" },
      use_icons = true,
    })

    -- Set keymaps
    vim.keymap.set("n", "<leader>vd", "<cmd>DiffviewOpen<CR>", { desc = "Open Diffview" })
    vim.keymap.set("n", "<leader>vc", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" })
    vim.keymap.set("n", "<leader>vh", "<cmd>DiffviewFileHistory<CR>", { desc = "File History" })
  end,
}

