# CLAUDE.md

Minimal Neovim config for the vscode-neovim extension. Branch `vscode`, cut from `master`.

Scope: text editing and keybinds only. VS Code owns windows, panes, the file tree, language servers, formatting, and completion. Do not add plugins for those. LSP keymaps forward to VS Code commands.

## Structure

- `init.lua` - The whole config: options, `vim.pack` plugins, keymaps, autocommands.
- `nvim-pack-lock.json` - Plugin lock file written by `vim.pack`.

## Plugins (`vim.pack`)

- `leap.nvim` + `vim-repeat` - `s` to leap
- `mini.nvim` - only `mini.ai` (extended text objects)

## Key Mappings

- Leader: `<space>`
- `jk`/`kj` - Exit insert mode. VS Code owns insert mode, so `init.lua` cannot map these. They live in VS Code `settings.json`:

  ```json
  "vscode-neovim.compositeKeys": {
    "jk": { "command": "vscode-neovim.escape" },
    "kj": { "command": "vscode-neovim.escape" }
  }
  ```
- `<Esc>` - Clear search highlight
- `s` - Leap
- `,,` - Previous editor | `,d` - Close editor
- `<leader>f` - Format buffer (selection in visual mode)

**LSP (VS Code commands):** `gd` definition, `gr` references, `gI` implementation, `gD` declaration, `<leader>ds` document symbols, `<leader>ws` workspace symbols, `<leader>rn` rename, `<leader>ca` code action, `<leader>th` toggle inlay hints

All VS Code keymaps live in the `if vim.g.vscode` block.

Keymaps that call VS Code commands go inside the `if vim.g.vscode` block and use `require('vscode').action`.
