-- ~/.config/nvim/lua/plugins/whichkey.lua
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern";
  },
  keys = {
    { "<leader>b", group = "buffer" },
    { "<leader>c", group = "code" },
    { "<leader>e", group = "explorer" },
    { "<leader>f", group = "find" },
    { "<leader>g", group = "git" },
    { "<leader>h", group = "hunks" },
    { "<leader>r", group = "rename" },
    { "<leader>s", group = "search" },
    { "<leader>t", group = "toggle/terminal" },
    { "<leader>w", group = "workspace" },
  }
}
