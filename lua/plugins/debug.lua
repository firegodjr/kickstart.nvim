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
        {
          '<F5>',
          function()
            local overseer = require 'overseer'
            local running_tasks = overseer.list_tasks { status = 'RUNNING' }

            if #running_tasks > 0 then
              vim.ui.select({ 'Yes', 'No' }, {
                prompt = 'Build is running. Cancel and start debugging?',
              }, function(choice)
                if choice == 'Yes' then
                  for _, task in ipairs(running_tasks) do
                    task:stop()
                  end
                  dap.continue()
                end
              end)
            else
              dap.continue()
            end
          end,
          desc = 'Debug: Start/Continue',
        },
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
          'coreclr',
          'codelldb',
        },
      }

      dap.configurations.cs = {
        {
          name = 'Attach to Running Process',
          type = 'coreclr',
          request = 'attach',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
      }

      -- Rust: auto-build with cargo before launching the debugger
      dap.configurations.rust = {
        {
          name = 'Launch (cargo build)',
          type = 'codelldb',
          request = 'launch',
          program = function()
            vim.fn.system 'cargo build'
            if vim.v.shell_error ~= 0 then
              vim.notify('Cargo build failed! Run :!cargo build for details.', vim.log.levels.ERROR)
              return ''
            end
            -- Find the binary name from cargo metadata
            local ok, metadata = pcall(vim.json.decode, vim.fn.system 'cargo metadata --no-deps --format-version 1')
            if ok then
              for _, pkg in ipairs(metadata.packages or {}) do
                for _, target in ipairs(pkg.targets or {}) do
                  if vim.tbl_contains(target.kind, 'bin') then
                    return (metadata.target_directory or (vim.fn.getcwd() .. '/target')) .. '/debug/' .. target.name
                  end
                end
              end
            end
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
      }

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.after.event_initialized['notify_running'] = function(session)
        -- Send desktop notification when debug session starts (for long builds)
        -- Fails silently if notify-send isn't installed
        local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
        local config_name = session and session.config and session.config.name or nil
        local message = config_name and (config_name .. ' (' .. project_name .. ')') or project_name
        vim.fn.jobstart({ 'notify-send', 'Neovim Debug', message .. ' is now running', '--icon=dialog-information' }, {
          detach = true,
          on_stderr = function() end, -- Suppress errors
        })
      end
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close

      require('nvim-dap-virtual-text').setup()
    end,
  },
}
