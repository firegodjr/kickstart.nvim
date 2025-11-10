return {
  -- nvim-dap | Run/Debug projects inside of neovim
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      -- Single window for debug info & repl
      'igorlfs/nvim-dap-view',
      -- Required dependency for nvim-dap-ui
      'nvim-neotest/nvim-nio',
      -- Adds virtual text for variables
      'theHamsta/nvim-dap-virtual-text',
      -- Installs the debug adapters for you
      'williamboman/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',
    },
    keys = function(_, keys)
      local dap = require 'dap'
      local dapui = require 'dap-view'
      return {
        -- Basic debugging keymaps
        { '<F5>', dap.continue, desc = 'Debug: Start/Continue' },
        { '<F11>', dap.step_into, desc = 'Debug: Step Into' },
        { '<leader><F11>', dap.step_into, desc = 'Debug: Step Into' },
        { '<F10>', dap.step_over, desc = 'Debug: Step Over' },
        { '<F8>', dap.step_out, desc = 'Debug: Step Out' },
        { '<leader>dq', dap.terminate, desc = 'Debug: Quit' },
        { '<leader>db', dap.toggle_breakpoint, desc = 'Debug: Toggle Breakpoint' },
        {
          '<leader>dB',
          function()
            dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
          end,
          desc = 'Debug: Set Breakpoint',
        },
        -- Dap-View keymaps
        {
          '<leader>dt',
          function()
            dapui.toggle(true)
          end,
          desc = 'Debug: Toggle UI',
        },
        -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
        { '<F7>', dapui.toggle, desc = 'Debug: See last session result.' },
        -- TODO: These are currently broken w/ nvim-dap-view
        -- Add word under cursor to watches
        -- { '<leader>de',
        --   function()
        --     dapui.elements.watches.add(vim.fn.expand('<cword>'))
        --   end,
        --   desc = 'Debug: Add word to watch'
        -- },
        -- {
        --   '<leader>dE',
        --   function()
        --     dapui.elements.watches.add(vim.fn.input 'Watch condition:')
        --   end,
        --   desc = 'Debug: Add watch condition',
        -- },
        unpack(keys),
      }
    end,
    config = function()
      local dap = require 'dap'
      local dapui = require 'dap-view'

      dap.configurations.cs = {
        {
          name = 'Attach to Running Process',
          type = 'coreclr',
          request = 'attach',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}'
        }
      }

      require('mason-nvim-dap').setup {
        -- Makes a best effort to setup the various debuggers with
        -- reasonable debug configurations
        automatic_installation = true,

        -- You can provide additional configuration to the handlers,
        -- see mason-nvim-dap README for more information
        handlers = {
          -- Default setup
          function(config)
            require('mason-nvim-dap').default_setup(config)
          end,
        },

        -- You'll need to check that you have the required things installed
        -- online, please don't ask me how to install them :)
        ensure_installed = {
          -- Update this to ensure that you have the debuggers for the langs you want
          'netcoredbg',
          'delve',
        },
      }

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close

      require('nvim-dap-virtual-text').setup()
    end,
  },
}
