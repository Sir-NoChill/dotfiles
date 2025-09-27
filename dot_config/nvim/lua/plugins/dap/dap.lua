return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "theHamsta/nvim-dap-virtual-text",
  },
  config = function()
    local dap = require("dap")
    dap.adapters.lldb = {
      type = 'executable',
      command = '/usr/bin/codelldb',
      name = 'lldb'
    }
    dap.configurations.cpp = {
      {
          name = 'Launch',
          type = 'lldb',
          request = 'launch',
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          args = {},
      }
    }

    dap.configurations.c = dap.configurations.cpp

    dap.configurations.rust = {
      {
          name = 'Launch',
          type = 'rust-lldb',
          request = 'launch',
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          args = {},

          initCommands = function()
            local rustc_sysroot = vim.fn.system("rustc --print sysroot")
            assert(vim.v.shell_error == 0, "Failed to get sysroot")

            local script_file = rustc_sysroot .. '/lib/rustlib/etc/lldb_lookup.py'
            local commands_file = rustc_sysroot .. '/lib/rustlib/etc/lldb_commands'

            return {
              ([[!command script import '%s']]):format(script_file),
              ([[command source '%s']]):format(commands_file),
            }
          end,
      }
    }
  end
}
