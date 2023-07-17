-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Move acroll panes with ctrl-[hjkl]
vim.keymap.set("n", "<C-h>", function()
	vim.cmd(":wincmd h")
end)
vim.keymap.set("n", "<C-j>", function()
	vim.cmd(":wincmd j")
end)
vim.keymap.set("n", "<C-k>", function()
	vim.cmd(":wincmd k")
end)
vim.keymap.set("n", "<C-l>", function()
	vim.cmd(":wincmd l")
end)

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
-- vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })
