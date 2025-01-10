-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- LSP Server to use for PHP.
vim.g.lazyvim_php_lsp = "phpactor"

-- revert from updated default - if you don't have the `fzf`` executable installed locally
vim.g.lazyvim_picker = "telescope"

vim.g.lazyvim_ruby_lsp = "ruby_lsp"
vim.g.lazyvim_ruby_formatter = "rubocop"
