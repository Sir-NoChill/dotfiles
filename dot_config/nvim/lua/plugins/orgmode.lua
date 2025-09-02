-- ~/.config/nvim/lua/plugins/orgmode.lua
return {
  "nvim-orgmode/orgmode",
  event = "VeryLazy",
  ft = { "org" },
  config = function()
    -- Setup orgmode
    require("orgmode").setup({
      org_agenda_files = "~/orgfiles/**/*",
      org_default_notes_file = "~/orgfiles/refile.org",
    })

    -- add ~org~ to ignore_install
    require('nvim-treesitter.configs').setup({
      ensure_installed = 'all',
      ignore_install = { 'org' },
    })
  end,
}
