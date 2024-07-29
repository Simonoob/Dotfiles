-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--Add any additional keymaps here

require("which-key").add({ "<leader>d", "which_key_ignore", desc = "delete", mode = "n" })
vim.keymap.set("n", "<leader>dm", "<Esc>:delm! | delm A-Z0-9<CR>", { desc = "delete all marks" })
