return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
    {
      "debugloop/telescope-undo.nvim",
    },
  },
  opts = {
    extensions_list = { "fzf", "undo" },
  },
}
