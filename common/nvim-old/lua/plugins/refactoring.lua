local pick = function()
	return require("telescope").extensions.refactoring.refactors()
	-- local refactoring = require "refactoring"
	-- refactoring.select_refactor()
end

return {
	{
		"ThePrimeagen/refactoring.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		keys = {
			{ "<leader>cr", "", desc = "+refactor", mode = { "n", "v" } },
			{
				"<leader>crs",
				pick,
				mode = "v",
				desc = "Refactor",
			},
			{
				"<leader>cri",
				"<cmd>Refactor inline_var<cr>",
				mode = { "n", "v" },
				desc = "Inline Variable",
			},
			{
				"<leader>crb",
				"<cmd>Refactor extract_block<cr>",
				desc = "Extract Block",
			},
			{
				"<leader>crf",
				function()
					return require("refactoring").refactor("Extract Block To File")
				end,
				desc = "Extract Block To File",
			},
			{
				"<leader>crP",
				function()
					return require("refactoring").debug.printf({ below = false })
				end,
				desc = "Debug Print",
			},
			{
				"<leader>crp",
				function()
					return require("refactoring").debug.print_var({ normal = true })
				end,
				desc = "Debug Print Variable",
			},
			{
				"<leader>crc",
				function()
					return require("refactoring").debug.cleanup({})
				end,
				desc = "Debug Cleanup",
			},
			{
				"<leader>rf",
				function()
					return require("refactoring").refactor("Extract Function")
				end,
				mode = "v",
				desc = "Extract Function",
			},
			{
				"<leader>crF",
				"<cmd>Refactor extract_to_file<cr>",
				mode = "v",
				desc = "Extract Function To File",
			},
			{
				"<leader>crx",
				function()
					require("refactoring").refactor("Extract Variable")
				end,
				mode = "v",
				desc = "Extract Variable",
			},
			{
				"<leader>crp",
				function()
					require("refactoring").debug.print_var()
				end,
				mode = "v",
				desc = "Debug Print Variable",
			},
		},
		opts = {
			prompt_func_return_type = {
				go = false,
				java = false,
				cpp = false,
				c = false,
				h = false,
				hpp = false,
				cxx = false,
			},
			prompt_func_param_type = {
				go = false,
				java = false,
				cpp = false,
				c = false,
				h = false,
				hpp = false,
				cxx = false,
			},
			printf_statements = {},
			print_var_statements = {},
			show_success_message = true, -- shows a message with information about the refactor on success
			-- i.e. [Refactor] Inlined 3 variable occurrences
		},
		config = function(_, opts)
			require("refactoring").setup(opts)
		end,
	},
}
