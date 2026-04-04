-- ~/.config/nvim/lua/lsp/tblgen-lsp.lua

vim.lsp.config['tblgen'] = {
  -- Command and arguments to start the server.
  cmd = { 'tblgen-lsp-server' },
  -- Filetypes to automatically attach to.
  filetypes = { 'td' },
  -- Sets the "workspace" to the directory where any of these files is found.
  -- Files that share a root directory will reuse the LSP server connection.
  -- Nested lists indicate equal priority, see |vim.lsp.Config|.
  root_markers = { '.clangd', '.git', '.jj' },
  -- Specific settings to send to the server. The schema is server-defined.
  -- Example: https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json
  settings = {}
}

-- Use vim.lsp.enable() to enable the config. Example:

vim.lsp.enable('tblgen')


