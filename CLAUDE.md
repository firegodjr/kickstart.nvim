# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Neovim configuration based on kickstart.nvim, extended with additional plugins and customizations. The configuration is written in Lua and uses lazy.nvim as the plugin manager.

## Architecture

### Entry Point
- `init.lua` - Main configuration entry point that:
  - Sets leader key to space
  - Loads core options and keymaps
  - Bootstraps lazy.nvim plugin manager
  - Loads core plugins via `require('lazy').setup({ require 'core' })`
  - Loads theme from `current-theme.lua` (managed by telescope-themes extension)
  - Loads compatibility modules based on environment (Windows, Neovide, etc.)
  - Supports per-project config via `.nvim.lua` files (using exrc.nvim)

### Module Structure
- `lua/core.lua` - Core plugin configurations (LSP, completion, treesitter, telescope, etc.)
- `lua/plugins/*.lua` - Additional plugin configurations organized by category:
  - `debug.lua` - nvim-dap debugger setup (F5, F10, F11 keys)
  - `ide.lua` - IDE enhancements (go.nvim, easy-dotnet.nvim, refactoring.nvim)
  - `ui.lua` - UI-related plugins (leap.nvim, neo-tree, lualine, colorschemes, etc.)
  - `git.lua` - Git integrations
  - `autopairs.lua` - Auto-pairing functionality
  - `obsidian.lua` - Obsidian integration
  - `overseer.lua` - Task runner
  - `llm.lua` - LLM integrations
  - `render-markdown.lua` - Markdown rendering
  - `template-literal-comments.lua` - Template literal comment support
  - `fun.lua` - Fun/experimental plugins
- `lua/compat/*.lua` - Platform/tool-specific compatibility layers:
  - `volar.lua` - Vue.js language server setup with TypeScript integration
  - `windows.lua` - Windows-specific configurations
  - `neovide.lua` - Neovide GUI-specific settings
  - `kl.lua` - Custom KL plugin (loaded conditionally via `.nvim.lua` global flag)

### Plugin Loading
Core plugins are imported via `require 'core'`, which itself imports all files from `lua/plugins/` directory via `{ import = 'plugins' }` at the end of the plugin specification.

## Language Support

### Built-in LSP Servers (via Mason)
- `ts_ls` - TypeScript/JavaScript (with Vue support via @vue/typescript-plugin)
- `volar` - Vue.js (configured for non-hybrid mode)
- `omnisharp` - C# (with extended LSP support via omnisharp-extended-lsp.nvim)
- `lua_ls` - Lua (configured for Neovim development)

### Language-Specific Features
- **C#**: Attach to running process debugging, test runner via easy-dotnet.nvim
- **Go**: Auto-format with goimports on save, go.nvim for Go-specific features
- **Less**: Auto-compile to minified CSS on save
- **Vue**: Integrated TypeScript support with Volar and ts_ls working together

### Formatting
- Conform.nvim handles formatting with `<leader>f`
- Format-on-save can be toggled via `vim.g.format_on_save` (set in per-project `.nvim.lua`)
- Lua formatting via stylua

## Key Mappings

### Custom Leader Mappings
- Leader key: `<space>`
- `jk` / `kj` - Exit insert mode
- `,,` - Switch to previous buffer
- `,d` - Delete current buffer and go to previous
- `<leader>FF` - Fix DOS-formatted files (remove ^M characters)

### Navigation (leap.nvim)
- `s` - Leap
- `S` - Leap from window

### Which-Key Groups
- `<leader>c` - Code actions
- `<leader>d` - Document/Debug
- `<leader>r` - Rename/Refactor
- `<leader>s` - Search (Telescope)
- `<leader>g` - Git
- `<leader>w` - Workspace
- `<leader>h` - Git hunks
- `<leader>t` - Tests
- `<leader>D` - Dotnet commands

### Debugging (nvim-dap)
- `F5` - Start/Continue debugging
- `F10` - Step over
- `F11` - Step into
- `F8` - Step out
- `F7` - Toggle debug UI
- `<leader>db` - Toggle breakpoint
- `<leader>dB` - Set conditional breakpoint
- `<leader>dq` - Quit debugging
- `<leader>dt` - Toggle debug UI

### Testing
- `<leader>tt` - Toggle test runner (C# via easy-dotnet)
- `<leader>tr` - Run test
- `<leader>td` - Debug test
- `<leader>tR` - Run all tests

### C# Development (easy-dotnet.nvim)
- `<leader>DD` - Show Dotnet commands
- `<leader>Db` - Build project
- `<leader>Dw` - Watch mode

## Special Features

### Per-Project Configuration
- Supports `.nvim.lua` files in project root for project-specific settings
- Example: Set `vim.g.use_kl = true` to enable the KL plugin
- Example: Set `vim.g.format_on_save = true` to enable format-on-save

### Theme Management
- Telescope-themes extension for browsing/applying colorschemes
- Selected theme persists to `lua/current-theme.lua`
- Access via `<leader>sC`

### C# Debugging
- Special configuration to attach to running .NET processes
- Uses netcoredbg adapter installed via Mason

### Codelens
- Automatically refreshes on CursorHold
- Highlight group forced to neutral color (#777777) to work around theme issues

### Treesitter
- Auto-installs parsers as needed
- Disabled for Go files (due to performance issues)
- Disabled for files larger than 100KB

## Development Workflow

When modifying this configuration:
1. Changes to plugin configs require a Neovim restart
2. Use `:Lazy` to check plugin status and update plugins
3. Use `:Mason` to manage LSP servers and tools
4. Use `:checkhealth` to diagnose issues
5. Plugin additions go in `lua/plugins/*.lua` files, not in `core.lua`
