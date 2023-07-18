vim.keymap.set("n", "<leader>gg", ":LazyGit<CR>", { desc = "Lazy[G]it", silent = true })
return {
	"kdheepak/lazygit.nvim",
	-- optional for floating window border decoration
	requires = {
		"nvim-lua/plenary.nvim",
	},
}
