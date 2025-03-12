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
			{ "<leader>cR", "", desc = "refactor", mode = { "n", "x" } },
			{ "<leader>cRf", "", desc = "function", mode = { "n", "x" } },
			{ "<leader>cRv", "", desc = "variable", mode = { "n", "x" } },
			{ "<leader>cRb", "", desc = "block", mode = { "n", "x" } },
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

			-- [[KEYMAPS]]
			-- prompt for a refactor
			vim.keymap.set({ "n", "x" }, "<leader>cRr", function()
				require("refactoring").select_refactor()
			end)

			-- [[functions]]
			vim.keymap.set({ "n", "x" }, "<leader>cRfe", function()
				return require("refactoring").refactor("Extract Function")
			end, { expr = true, desc = "Extract function" })
			vim.keymap.set({ "n", "x" }, "<leader>cRff", function()
				return require("refactoring").refactor("Extract Function To File")
			end, { expr = true, desc = "Extract function to File" })
			vim.keymap.set({ "n", "x" }, "<leader>cRfi", function()
				return require("refactoring").refactor("Inline Function")
			end, { expr = true, desc = "Inline function" })

			-- [[variables]]
			vim.keymap.set({ "n", "x" }, "<leader>cRve", function()
				return require("refactoring").refactor("Extract Variable")
			end, { expr = true, desc = "Extract variable" })
			vim.keymap.set({ "n", "x" }, "<leader>cRvi", function()
				return require("refactoring").refactor("Inline Variable")
			end, { expr = true, desc = "Inline variable" })

			-- [[blocks]]
			vim.keymap.set({ "n", "x" }, "<leader>cRbb", function()
				return require("refactoring").refactor("Extract Block")
			end, { expr = true, desc = "Extract block" })
			vim.keymap.set({ "n", "x" }, "<leader>cRbf", function()
				return require("refactoring").refactor("Extract Block To File")
			end, { expr = true, desc = "Extract block to file" })
		end,
	},
}
