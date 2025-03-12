return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate", -- Automatically updates parsers when plugins are installed
	event = { "BufReadPost", "BufNewFile" }, -- Lazy loads only when buffers are read/created
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects", -- Adds text objects for code navigation
		"windwp/nvim-ts-autotag", -- Auto close/rename HTML/JSX tags (essential for web dev)
	},
	config = function()
		require("nvim-treesitter.configs").setup({
			-- Required fields that were missing
			modules = {},
			sync_install = false,
			auto_install = true,
			ignore_install = {},

			-- Languages to install parsers for (crucial for web development)
			ensure_installed = {
				"bash",
				"css",
				"html",
				"javascript",
				"json",
				"lua",
				"markdown",
				"markdown_inline",
				"python",
				"regex",
				"tsx", -- React JSX with TypeScript
				"typescript",
				"vim",
				"yaml",
			},
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false, -- Disables slower vim regex highlighting
			},
			indent = { enable = true }, -- Better auto-indentation based on syntax
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>", -- Start selection with Ctrl+Space
					node_incremental = "<C-space>", -- Expand selection with repeated Ctrl+Space
					scope_incremental = "<nop>",
					node_decremental = "<bs>", -- Shrink selection with Backspace
				},
			},
			autotag = { enable = true }, -- Auto close/rename HTML and JSX tags
			textobjects = {
				-- Custom text objects for selecting code blocks
				select = {
					enable = true,
					lookahead = true, -- Extends selection to next match if needed
					keymaps = {
						-- Select function outer/inner content with af/if
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						["ic"] = "@class.inner",
						["aa"] = "@parameter.outer",
						["ia"] = "@parameter.inner",
					},
				},
				-- Navigation between code blocks (functions, classes)
				move = {
					enable = true,
					set_jumps = true, -- Adds movement to jumplist for navigation with C-o/C-i
					goto_next_start = {
						["]f"] = "@function.outer", -- Move to next function with ]f
						["]c"] = "@class.outer",
					},
					goto_next_end = {
						["]F"] = "@function.outer",
						["]C"] = "@class.outer",
					},
					goto_previous_start = {
						["[f"] = "@function.outer", -- Move to previous function with [f
						["[c"] = "@class.outer",
					},
					goto_previous_end = {
						["[F"] = "@function.outer",
						["[C"] = "@class.outer",
					},
				},
			},
		})
	end,
}
