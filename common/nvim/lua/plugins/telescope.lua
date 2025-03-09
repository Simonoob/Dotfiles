-- Find build command for telescope-fzf-native
local build_cmd
for _, cmd in ipairs({ "make", "cmake", "gmake" }) do
	if vim.fn.executable(cmd) == 1 then
		build_cmd = cmd
		break
	end
end

-- Find best file finder command
local function find_command()
	if 1 == vim.fn.executable("rg") then
		return { "rg", "--files", "--color", "never", "-g", "!.git" }
	elseif 1 == vim.fn.executable("fd") then
		return { "fd", "--type", "f", "--color", "never", "-E", ".git" }
	elseif 1 == vim.fn.executable("fdfind") then
		return { "fdfind", "--type", "f", "--color", "never", "-E", ".git" }
	elseif 1 == vim.fn.executable("find") and vim.fn.has("win32") == 0 then
		return { "find", ".", "-type", "f" }
	elseif 1 == vim.fn.executable("where") then
		return { "where", "/r", ".", "*" }
	end
end

return {
	-- Telescope fuzzy finder
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		version = false, -- use HEAD
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = (build_cmd ~= "cmake") and "make"
					or "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
				enabled = build_cmd ~= nil,
				config = function(plugin)
					-- Load the fzf extension
					vim.schedule(function()
						local ok, err = pcall(require("telescope").load_extension, "fzf")
						if not ok then
							local lib = plugin.dir .. "/build/libfzf." .. (vim.fn.has("win32") == 1 and "dll" or "so")
							if not vim.loop.fs_stat(lib) then
								vim.notify("telescope-fzf-native.nvim not built. Rebuilding...", vim.log.levels.WARN)
								require("lazy").build({ plugins = { plugin }, show = false })
							else
								vim.notify("Failed to load telescope-fzf-native: " .. err, vim.log.levels.ERROR)
							end
						end
					end)
				end,
			},
		},
		keys = {
			-- Quick access
			{ "<leader>,", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Switch Buffer" },
			{ "<leader>:", "<cmd>Telescope command_history<cr>", desc = "Command History" },

			-- Files
			{
				"<leader>fb",
				"<cmd>Telescope buffers sort_mru=true sort_lastused=true ignore_current_buffer=true<cr>",
				desc = "Buffers",
			},
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
			{
				"<leader>fF",
				"<cmd>lua require('telescope.builtin').find_files({ cwd = vim.fn.getcwd() })<cr>",
				desc = "Find Files (cwd)",
			},
			-- Hidden and ignored files only
			{
				"<leader>fh",
				function()
					require("telescope.builtin").find_files({
						find_command = {
							"fd",
							"--type",
							"f",
							"--hidden",
							"--no-ignore-vcs",
						},
						prompt_title = "Find Hidden Files Only",
					})
				end,
				desc = "Find Hidden Files Only",
			},
			-- All files (hidden + ignored + normal)
			{
				"<leader>fa",
				function()
					require("telescope.builtin").find_files({
						hidden = true,
						no_ignore = true,
						prompt_title = "Find All Files",
					})
				end,
				desc = "Find All Files",
			},
			{ "<leader>fg", "<cmd>Telescope git_files<cr>", desc = "Find Files (git-files)" },
			{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
			{
				"<leader>fR",
				"<cmd>lua require('telescope.builtin').oldfiles({ cwd = vim.fn.getcwd() })<cr>",
				desc = "Recent Files (cwd)",
			},

			-- Git
			{ "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Git Commits" },
			{ "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "Git Status" },

			-- Search
			{ '<leader>s"', "<cmd>Telescope registers<cr>", desc = "Registers" },
			{ "<leader>sa", "<cmd>Telescope autocommands<cr>", desc = "Auto Commands" },
			{ "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer" },
			{ "<leader>sc", "<cmd>Telescope command_history<cr>", desc = "Command History" },
			{ "<leader>sC", "<cmd>Telescope commands<cr>", desc = "Commands" },
			{ "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "Document Diagnostics" },
			{ "<leader>sD", "<cmd>Telescope diagnostics<cr>", desc = "Workspace Diagnostics" },
			{ "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Grep" },
			{
				"<leader>sG",
				"<cmd>lua require('telescope.builtin').live_grep({ cwd = vim.fn.getcwd() })<cr>",
				desc = "Grep (cwd)",
			},
			-- Grep in hidden files only
			{
				"<leader>sgh",
				function()
					require("telescope.builtin").live_grep({
						additional_args = function()
							return { "--hidden", "--no-ignore-vcs" }
						end,
						prompt_title = "Grep (Hidden Files Only)",
					})
				end,
				desc = "Grep (hidden files only)",
			},
			-- Grep in all files
			{
				"<leader>sga",
				function()
					require("telescope.builtin").live_grep({
						hidden = true,
						no_ignore = true,
						prompt_title = "Grep (All Files)",
					})
				end,
				desc = "Grep (all files)",
			},
			{ "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Help Pages" },
			{ "<leader>sH", "<cmd>Telescope highlights<cr>", desc = "Search Highlight Groups" },
			{ "<leader>sj", "<cmd>Telescope jumplist<cr>", desc = "Jumplist" },
			{ "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Key Maps" },
			{ "<leader>sl", "<cmd>Telescope loclist<cr>", desc = "Location List" },
			{ "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
			{ "<leader>sm", "<cmd>Telescope marks<cr>", desc = "Jump to Mark" },
			{ "<leader>so", "<cmd>Telescope vim_options<cr>", desc = "Options" },
			{ "<leader>sR", "<cmd>Telescope resume<cr>", desc = "Resume" },
			{ "<leader>sq", "<cmd>Telescope quickfix<cr>", desc = "Quickfix List" },
			{
				"<leader>sw",
				"<cmd>lua require('telescope.builtin').grep_string({ word_match = '-w' })<cr>",
				desc = "Word",
			},
			{
				"<leader>sW",
				"<cmd>lua require('telescope.builtin').grep_string({ cwd = vim.fn.getcwd(), word_match = '-w' })<cr>",
				desc = "Word (cwd)",
			},
			{
				"<leader>sw",
				"<cmd>lua require('telescope.builtin').grep_string()<cr>",
				mode = "v",
				desc = "Selection",
			},
			{
				"<leader>sW",
				"<cmd>lua require('telescope.builtin').grep_string({ cwd = vim.fn.getcwd() })<cr>",
				mode = "v",
				desc = "Selection (cwd)",
			},
			{
				"<leader>ss",
				function()
					require("telescope.builtin").lsp_document_symbols()
				end,
				desc = "Document Symbols",
			},
			{
				"<leader>sS",
				function()
					require("telescope.builtin").lsp_dynamic_workspace_symbols()
				end,
				desc = "Workspace Symbols",
			},
		},
		opts = function()
			local actions = require("telescope.actions")

			-- Function to support trouble plugin if installed
			local open_with_trouble = function(...)
				return vim.cmd.Trouble("telescope")
			end

			-- Find hidden files handler
			local find_files_with_hidden = function()
				local action_state = require("telescope.actions.state")
				local line = action_state.get_current_line()
				require("telescope.builtin").find_files({
					find_command = { "fd", "--type", "f", "--hidden", "--no-ignore-vcs" },
					prompt_title = "Find Hidden Files Only",
					default_text = line,
				})
			end

			-- Find all files handler
			local find_files_all = function()
				local action_state = require("telescope.actions.state")
				local line = action_state.get_current_line()
				require("telescope.builtin").find_files({
					hidden = true,
					no_ignore = true,
					prompt_title = "Find All Files",
					default_text = line,
				})
			end

			return {
				defaults = {
					prompt_prefix = " ",
					selection_caret = " ",
					-- Open files in the first valid window
					get_selection_window = function()
						local wins = vim.api.nvim_list_wins()
						table.insert(wins, 1, vim.api.nvim_get_current_win())
						for _, win in ipairs(wins) do
							local buf = vim.api.nvim_win_get_buf(win)
							if vim.bo[buf].buftype == "" then
								return win
							end
						end
						return 0
					end,
					mappings = {
						i = {
							["<c-t>"] = open_with_trouble,
							["<a-t>"] = open_with_trouble,
							["<a-h>"] = find_files_with_hidden,
							["<a-a>"] = find_files_all,
							["<C-Down>"] = actions.cycle_history_next,
							["<C-Up>"] = actions.cycle_history_prev,
							["<C-f>"] = actions.preview_scrolling_down,
							["<C-b>"] = actions.preview_scrolling_up,
						},
						n = {
							["q"] = actions.close,
						},
					},
				},
				pickers = {
					find_files = {
						find_command = find_command(),
						prompt_title = "Find Files",
						hidden = false, -- Default to not showing hidden files
						no_ignore = false, -- Default to respecting ignore files
					},
					live_grep = {
						prompt_title = "Live Grep",
						-- Ensures grep searches respect .gitignore by default
						additional_args = function()
							return {}
						end,
					},
				},
			}
		end,
	},

	-- LSP integration
	{
		"neovim/nvim-lspconfig",
		optional = true,
		dependencies = { "nvim-telescope/telescope.nvim" },
		keys = {
			{
				"gd",
				function()
					require("telescope.builtin").lsp_definitions({ reuse_win = true })
				end,
				desc = "Goto Definition",
			},
			{ "gr", "<cmd>Telescope lsp_references<cr>", desc = "References" },
			{
				"gI",
				function()
					require("telescope.builtin").lsp_implementations({ reuse_win = true })
				end,
				desc = "Goto Implementation",
			},
			{
				"gy",
				function()
					require("telescope.builtin").lsp_type_definitions({ reuse_win = true })
				end,
				desc = "Goto Type Definition",
			},
		},
	},

	-- Better UI for vim.ui.select/input
	{
		"stevearc/dressing.nvim",
		lazy = true,
		init = function()
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.select = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.select(...)
			end
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.input = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.input(...)
			end
		end,
	},
}
