return {
  {"catppuccin/nvim", name = "catppuccin", priority = 1000},
  {'morhetz/gruvbox'},
  {'sainnhe/gruvbox-material'},
  {'loganswartz/sunburn.nvim', dependencies={'loganswartz/polychrome.nvim'}},
  {'zenbones-theme/zenbones.nvim', dependencies={'rktjmp/lush.nvim'}},
  {'Mofiqul/vscode.nvim'},
  {'gmr458/vscode_modern_theme.nvim'},
  {'slugbyte/lackluster.nvim'},
  {'olivercederborg/poimandres.nvim'},
  {'wnkz/monoglow.nvim'},
  {'aliqyan-21/darkvoid.nvim'},
  {'scottmckendry/cyberdream.nvim'},
  {'AlexvZyl/nordic.nvim'},
  {'rafamadriz/neon'},
  {
    url = 'https://github.com/firegodjr/monokai-pro.nvim.git',
    priority = 1000, -- Make sure to load this before all the other start plugins.
  }
}
