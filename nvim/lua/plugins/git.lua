return {
	-- Adds git releated signs to the gutter, as well as utilities for managing changes
	"lewis6991/gitsigns.nvim",
	opts = {
		-- See `:help gitsigns.txt`
		signs = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
		},
		on_attach = function(bufnr)
			vim.keymap.set(
				"n",
				"<leader>gp",
				require("gitsigns").prev_hunk,
				{ buffer = bufnr, desc = "[P]revious Hunk" }
			)
			vim.keymap.set("n", "<leader>gn", require("gitsigns").next_hunk, { buffer = bufnr, desc = "[N]ext Hunk" })
			vim.keymap.set(
				"n",
				"<leader>gp",
				require("gitsigns").preview_hunk,
				{ buffer = bufnr, desc = "[P]review hunk" }
			)
		end,
	},
}
