local vue_typescript_plugin_path = vim.fn.stdpath 'data' .. '/mason/bin/vue-language-server'

local lspconfig = require 'lspconfig'
lspconfig.ts_ls.setup {
  init_options = {
    plugins = {
      {
        name = '@vue/typescript-plugin',
        location = vue_typescript_plugin_path,
        languages = { 'vue' },
      },
    },
  },
}

lspconfig.volar.setup {
  init_options = {
    vue = {
      hybridMode = false,
    },
  },
}

-- You must make sure volar is setup
-- e.g. require'lspconfig'.volar.setup{}
-- See volar's section for more information
