return   {
  "williamboman/mason.nvim",
  opts = {
    ensure_installed = {
      -- lsp
      "bash-language-server",
      "cmake-language-server",
      "clangd",
      "dockerfile-language-server",
      "lua-language-server",
      "python-lsp-server",
      "shellcheck",
      "rust-analyzer",
      -- formatter
      "beautysh",
      "black",
      "clang-format",
      "isort",
      "prettier",
      "shellcheck",
      "stylua",
    },
  },
}
