# CLAUDE.md

Minimal Neovim config for the vscode-neovim extension. Branch `vscode`, cut from `master`.

Scope: text editing and keybinds only. VS Code owns windows, panes, the file tree, LSP, formatting, and completion. Do not add plugins or keymaps for those.

## Structure

- `init.lua` - The whole config: options, `vim.pack` plugins, keymaps, autocommands.
- `nvim-pack-lock.json` - Plugin lock file written by `vim.pack`.

## Plugins (`vim.pack`)

- `leap.nvim` + `vim-repeat` - `s` to leap
- `mini.nvim` - only `mini.ai` (extended text objects)

## Key Mappings

- Leader: `<space>`
- `jk`/`kj` - Exit insert mode
- `<Esc>` - Clear search highlight
- `s` - Leap
- `,,` - Previous editor | `,d` - Close editor (VS Code actions, guarded by `vim.g.vscode`)

Keymaps that call VS Code commands go inside the `if vim.g.vscode` block and use `require('vscode').action`.
