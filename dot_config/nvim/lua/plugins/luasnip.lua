return {
  "L3MON4D3/LuaSnip",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  build = "make install_jsregexp",
  config = function()
    -- LuaSnip configuration with jump keybindings
    -- Place this in your init.lua or in a separate config file

    local ls = require("luasnip")

    -- ============================================================
    -- LUASNIP CONFIGURATION
    -- ============================================================

    ls.config.set_config({
      -- Remember the last snippet's location for easy return
      history = true,

      -- Update snippets as you type
      update_events = "TextChanged,TextChangedI",

      -- Enable autotriggered snippets (if you want them)
      enable_autosnippets = false,

      -- For wrapping selected text (optional)
      store_selection_keys = "<C-s>",
    })

    -- ============================================================
    -- KEYBINDINGS FOR SNIPPET NAVIGATION
    -- ============================================================

    -- Jump forward through snippet tabstops with Ctrl-L
    vim.keymap.set({"i", "s"}, "<C-l>", function()
      if ls.expand_or_jumpable() then
        ls.expand_or_jump()
      end
    end, { silent = true, desc = "LuaSnip: Expand or jump forward" })

    -- Jump backward through snippet tabstops with Ctrl-H
    vim.keymap.set({"i", "s"}, "<C-h>", function()
      if ls.jumpable(-1) then
        ls.jump(-1)
      end
    end, { silent = true, desc = "LuaSnip: Jump backward" })

    -- Cycle through choice nodes with Ctrl-E (optional)
    vim.keymap.set({"i", "s"}, "<C-e>", function()
      if ls.choice_active() then
        ls.change_choice(1)
      end
    end, { silent = true, desc = "LuaSnip: Cycle choice node" })

    -- ============================================================
    -- LOAD SNIPPETS
    -- ============================================================

    -- Load snippets from the LuaSnip directory
    require("luasnip.loaders.from_lua").load({
      paths = "~/.config/nvim/lua/plugins/snippets"
    })

    -- Optional: Load friendly-snippets (VS Code style snippets)
    -- Uncomment if you have rafamadriz/friendly-snippets installed
    -- require("luasnip.loaders.from_vscode").lazy_load()

    -- ============================================================
    -- ADDITIONAL HELPER KEYBINDINGS (OPTIONAL)
    -- ============================================================

    -- Select current snippet (useful for editing)
    -- vim.keymap.set("i", "<C-u>", function()
    --   if ls.choice_active() then
    --     require("luasnip.extras.select_choice")()
    --   end
    -- end, { silent = true })

    -- Toggle between snippet expansion and jumping
    -- Alternative: Use Tab for expand/jump if preferred
    -- vim.keymap.set({"i", "s"}, "<Tab>", function()
    --   if ls.expand_or_jumpable() then
    --     ls.expand_or_jump()
    --   else
    --     return "<Tab>"
    --   end
    -- end, { silent = true, expr = true })

    -- vim.keymap.set({"i", "s"}, "<S-Tab>", function()
    --   if ls.jumpable(-1) then
    --     ls.jump(-1)
    --   else
    --     return "<S-Tab>"
    --   end
    -- end, { silent = true, expr = true })
  end,

}
