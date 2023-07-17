return {
	"zbirenbaum/copilot.lua",
	config = function()
		require("copilot").setup({
			panel = {
				enabled = true,
				auto_refresh = true,
				keymap = {
					jump_prev = "N",
					jump_next = "n",
					accept = "<CR>",
					refresh = "gr",
					open = "<C-o>",
				},
				layout = {
					position = "bottom", -- | top | left | right
					ratio = 0.4,
				},
			},
			suggestion = {
				enabled = false,
				auto_trigger = true, -- auto show suggestions on type
				debounce = 75,
				keymap = {
					accept = "<C-l>", -- more right to accept suggestion
					accept_word = false,
					accept_line = false,
					next = "<C-p>", -- [N]ext
					prev = "<C-n>", -- [P]rev
					dismiss = "<C-k>", --[K]ill
				},
			},
			filetypes = {
				yaml = false,
				markdown = false,
				help = false,
				gitcommit = false,
				gitrebase = false,
				hgcommit = false,
				svn = false,
				cvs = false,
				["."] = false,
			},
			copilot_node_command = "node", -- Node.js version must be > 16.x
			server_opts_overrides = {},
		})
		-- other
		vim.keymap.set("n", "<leader>co", ":Copilot panel<CR>", { desc = "[C]oPilot [O]pen" })
	end,
}
