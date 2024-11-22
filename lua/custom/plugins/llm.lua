return {
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
                    manual = true
                }
            })
        end,
        -- Start on vim enter
        event = "VimEnter",
        keys = {
            {'<F1>', function() require('codeium.virtual_text').complete() end, desc = 'Request AI completion', mode = 'i'},
        }
    },
}
