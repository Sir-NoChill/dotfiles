return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },
  {
    'https://github.com/bullets-vim/bullets.vim',
    dependencies = {},
    config = function() end,
  },
  {
    'https://codeberg.org/fd93/daily-notes.nvim',
    dependencies = {},
    opts = {
      -- writing = {
      --   root = {
      --     '~/Documents/notes'
      --   }
      -- }
    },
  },
}
