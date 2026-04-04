-- ~/.config/nvim/lua/lsp/clangd.lua
vim.lsp.config['clangd'] = {
  -- Command and arguments to start the server.
  cmd = { 'clangd' },
  -- Filetypes to automatically attach to.
  filetypes = { 'cpp', 'c', 'cc', 'h', 'hh', 'hpp', 'inc' },
  -- Sets the "workspace" to the directory where any of these files is found.
  -- Files that share a root directory will reuse the LSP server connection.
  -- Nested lists indicate equal priority, see |vim.lsp.Config|.
  root_markers = { 'compile_commands.json', '.clangd', '.git' },
  -- Specific settings to send to the server. The schema is server-defined.
  -- Example: https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json
  settings = {}
}

-- Use vim.lsp.enable() to enable the config. Example:

vim.lsp.enable('clangd')
