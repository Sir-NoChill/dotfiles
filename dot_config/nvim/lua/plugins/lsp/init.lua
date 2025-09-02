-- ~/.config/nvim/lua/plugins/lsp/init.lua
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "j-hui/fidget.nvim", -- LSP status updates
  },
  config = function()
    -- Import mason and lspconfig
    local mason = require("mason")
    local mason_lspconfig = require("mason-lspconfig")
    local mason_tool_installer = require("mason-tool-installer")

    -- Enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      -- List of servers for mason to install
      ensure_installed = {
        "lua_ls",        -- Lua
        "rust_analyzer", -- Rust
        "pyright",       -- Python
        "ts_ls",      -- TypeScript/JavaScript
        "html",          -- HTML
        "cssls",         -- CSS
        "tailwindcss",   -- Tailwind CSS
        "emmet_ls",      -- Emmet
        "prismals",      -- Prisma
        "svelte",        -- Svelte
        "nil_ls",        -- Nix
        "bashls",        -- Bash
        "jsonls",        -- JSON
        "yamlls",        -- YAML
        "marksman",      -- Markdown
        "dockerls",      -- Docker
        "gopls",         -- Go
      },
      -- Use the new automatic_enable setting instead of automatic_installation
      automatic_enable = true,
    })

    mason_tool_installer.setup({
      ensure_installed = {
        "prettier", -- prettier formatter
        "stylua",   -- lua formatter
        "isort",    -- python formatter
        "black",    -- python formatter
        "pylint",   -- python linter
        "eslint_d", -- js linter
      },
    })

    -- Setup fidget for LSP status
    require("fidget").setup({
      notification = {
        window = {
          winblend = 100,
        },
      },
    })

    local lspconfig = require("lspconfig")

    -- Change the Diagnostic symbols in the sign column (gutter)
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    -- Get default capabilities for LSP
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- Configure LSP servers manually using the new vim.lsp.config() API
    -- Default configuration for most servers
    local default_config = {
      capabilities = capabilities,
    }

    -- Setup servers that need default config
    local servers = {
      "rust_analyzer",
      "pyright",
      "ts_ls",
      "html",
      "cssls",
      "tailwindcss",
      "emmet_ls",
      "prismals",
      "svelte",
      "nil_ls",
      "bashls",
      "jsonls",
      "yamlls",
      "marksman",
      "dockerls",
      "gopls",
    }

    for _, server in ipairs(servers) do
      lspconfig[server].setup(default_config)
    end

    -- Configure lua_ls with special settings
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          -- Make the language server recognize "vim" global
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            -- Make language server aware of runtime files
            library = {
              [vim.fn.expand("$VIMRUNTIME/lua")] = true,
              [vim.fn.stdpath("config") .. "/lua"] = true,
            },
          },
          telemetry = {
            enable = false,
          },
        },
      },
    })
  end,
}
