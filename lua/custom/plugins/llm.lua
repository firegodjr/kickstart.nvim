return {
    -- -- ollama code refactoring
    -- { 
    --     "David-Kunz/gen.nvim",
    --     opts = {
    --         model = "mistral",
    --         show_prompt = true,
    --         show_model = true,
    --         display_mode = "split",
    --     }
    -- },
    -- codeium code insertion
    {
        "Exafunction/codeium.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "hrsh7th/nvim-cmp",
            "nvim-lualine/lualine.nvim",
        },
        config = function()
            local codeium = require("codeium")
            codeium.setup({
                enable_cmp_source = false,
                virtual_text = {
                    enabled = true,
                    manual = true,
                    idle_delay = 0,
                    key_bindings = {
                        accept = "<M-l>",
                        accept_word = false,
                        accept_line = false,
                        clear = false,
                        next = "<M-]>",
                        prev = "<M-[>"
                    }
                }
            })
        end,
        event = "BufEnter",
        keys = {
            {
                '<M-i>',
                function()
                    vim.cmd('startinsert')
                    vim.defer_fn(require('codeium.virtual_text').complete, 100)
                end,
                desc = 'Request AI completion'
            },
            {
                '<M-i>',
                function()
                    require('codeium.virtual_text').complete()
                end,
                desc = 'Request AI completion',
                mode = 'i'
            },
        }
    },
}
