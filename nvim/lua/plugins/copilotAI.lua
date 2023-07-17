return {
	"github/copilot.vim",
	config = function()
		vim.keymap.set("n", "<leader>co", ":Copilot<CR>", { desc = "[C]oPilot [O]pen" })
	end,
}
