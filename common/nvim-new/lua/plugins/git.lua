local gitsigns = {
	-- See `:help gitsigns` to understand what the configuration keys do
	-- Adds git related signs to the gutter, as well as utilities for managing changes
	"lewis6991/gitsigns.nvim",
	opts = {
		-- signs = {
		-- 	add = { text = "+" },
		-- 	change = { text = "~" },
		-- 	delete = { text = "_" },
		-- 	topdelete = { text = "‾" },
		-- 	changedelete = { text = "~" },
		-- },

		on_attach = function(buffer)
			local gs = package.loaded.gitsigns

			require("which-key").add({
				{ "<leader>gh", group = "hunk", desc = "LazyGit" },
			})
			local function map(mode, l, r, desc)
				vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
			end

			map("n", "]h", function()
				if vim.wo.diff then
					vim.cmd.normal({ "]c", bang = true })
				else
					gs.nav_hunk("next")
				end
			end, "Next Hunk")
			map("n", "[h", function()
				if vim.wo.diff then
					vim.cmd.normal({ "[c", bang = true })
				else
					gs.nav_hunk("prev")
				end
			end, "Prev Hunk")
			map("n", "]H", function()
				gs.nav_hunk("last")
			end, "Last Hunk")
			map("n", "[H", function()
				gs.nav_hunk("first")
			end, "First Hunk")
			map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
			map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
			map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
			map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
			map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
			map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
			map("n", "<leader>ghb", function()
				gs.blame_line({ full = true })
			end, "Blame Line")
			map("n", "<leader>ghB", function()
				gs.blame()
			end, "Blame Buffer")
			map("n", "<leader>ghd", gs.diffthis, "Diff This")
			map("n", "<leader>ghD", function()
				gs.diffthis("~")
			end, "Diff This ~")
			map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
		end,
	},
}

local lazygit = {
	"kdheepak/lazygit.nvim",
	lazy = true,
	cmd = {
		"LazyGit",
		"LazyGitConfig",
		"LazyGitCurrentFile",
		"LazyGitFilter",
		"LazyGitFilterCurrentFile",
	},
	-- optional for floating window border decoration
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	-- setting the keybinding for LazyGit with 'keys' is recommended in
	-- order to load the plugin when the command is run for the first time
	keys = {
		{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
	},
}

local advancedGitSearch = {
	"aaronhallaert/advanced-git-search.nvim",
	cmd = { "AdvancedGitSearch" },
	init = function()
		-- add keymaps
		require("which-key").add({ "<leader>ga", "which_key_ignore", desc = "advanced git search", mode = "n" })
		vim.keymap.set("n", "<Leader>gaf", "<Esc>:AdvancedGitSearch diff_commit_file<CR>", { desc = "file commits" })
		vim.keymap.set("n", "<Leader>gal", "<Esc>:AdvancedGitSearch diff_commit_line<CR>", { desc = "line commits" })

		-- optional: setup telescope before loading the extension
		require("telescope").setup({
			-- move this to the place where you call the telescope setup function
			extensions = {
				advanced_git_search = {
					-- Browse command to open commits in browser. Default fugitive GBrowse.
					-- {commit_hash} is the placeholder for the commit hash.
					browse_command = "GBrowse {commit_hash}",
					-- when {commit_hash} is not provided, the commit will be appended to the specified command seperated by a space
					-- browse_command = "GBrowse",
					-- => both will result in calling `:GBrowse commit`

					-- fugitive or diffview
					diff_plugin = "fugitive",
					-- customize git in previewer
					-- e.g. flags such as { "--no-pager" }, or { "-c", "delta.side-by-side=false" }
					git_flags = {},
					-- customize git diff in previewer
					-- e.g. flags such as { "--raw" }
					git_diff_flags = {},
					-- Show builtin git pickers when executing "show_custom_functions" or :AdvancedGitSearch
					show_builtin_git_pickers = false,
					entry_default_author_or_date = "author", -- one of "author" or "date"
					keymaps = {
						-- following keymaps can be overridden
						toggle_date_author = "<C-w>",
						open_commit_in_browser = "<C-o>",
						copy_commit_hash = "<C-y>",
						show_entire_commit = "<C-e>",
					},

					-- Telescope layout setup
					telescope_theme = {
						function_name_1 = {
							-- Theme options
						},
						function_name_2 = "dropdown",
						-- e.g. realistic example
						show_custom_functions = {
							layout_config = { width = 0.4, height = 0.4 },
						},
					},
				},
			},
		})

		require("telescope").load_extension("advanced_git_search")
	end,
	dependencies = {
		"nvim-telescope/telescope.nvim",
		-- to show diff splits and open commits in browser
		"tpope/vim-fugitive",
		-- to open commits in browser with fugitive
		"tpope/vim-rhubarb",
		-- optional: to replace the diff from fugitive with diffview.nvim
		-- (fugitive is still needed to open in browser)
		-- "sindrets/diffview.nvim",
	},
}

local openInGithub = {
	"almo7aya/openingh.nvim",
	cmd = {
		"OpenInGHRepo",
		"OpenInGHFile",
		"OpenInGHFileLines",
	},
	init = function()
		require("which-key").add(
			{ "<leader>gH", "which_key_ignore", desc = "GitHub", mode = "n" },
			{ "<leader>gHo", "which_key_ignore", desc = "open", mode = "n" }
		)

		-- for repository page
		vim.keymap.set("n", "<Leader>gHor", ":OpenInGHRepo <CR>", { desc = "Open [R]epo" })

		-- for current file page
		vim.keymap.set("n", "<Leader>gHof", ":OpenInGHFile <CR>", { desc = "Open [F]ile" })
		vim.keymap.set("n", "<Leader>gHol", ":OpenInGHFileLines <CR>", { desc = "Open [F]ile" })
	end,
}

return {
	gitsigns,
	lazygit,
	advancedGitSearch,
	openInGithub,
}
