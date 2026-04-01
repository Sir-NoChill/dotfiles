-- ~/.config/nvim/lua/plugins/autopairs.lua
local autopairs = require("nvim-autopairs")

autopairs.setup({
  check_ts = true, -- treesitter integration
  disable_filetype = { "TelescopePrompt" },
  ts_config = {
    lua = { "string", "source" },
    javascript = { "string", "template_string" },
    java = false,
  },
})

-- Make autopairs and completion work together
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
local cmp = require("cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
