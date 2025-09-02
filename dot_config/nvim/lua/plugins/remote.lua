-- ~/.config/nvim/lua/plugins/remote.lua
return {
  "chipsenkbeil/distant.nvim",
  branch = "v0.3",
  config = function()
    require('distant'):setup()
    
    -- Optional: Set up keymaps for remote development
    vim.keymap.set("n", "<leader>rc", "<cmd>DistantConnect<CR>", { desc = "Connect to remote" })
    vim.keymap.set("n", "<leader>rd", "<cmd>DistantDisconnect<CR>", { desc = "Disconnect from remote" })
  end
}
