-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require("telescope").setup({
	defaults = {
		mappings = {
			i = {
				["<C-u>"] = false,
				["<C-d>"] = false,
			},
		},
	},
})

-- Enable telescope fzf native, if installed
pcall(require("telescope").load_extension, "fzf")

require("which-key").register({
	f = {
		name = "Find", -- optional group name
	},
}, { prefix = "<leader>" })
-- See `:help telescope.builtin`
vim.keymap.set("n", "<leader>fh", require("telescope.builtin").oldfiles, { desc = "[H]istory" })
vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers, { desc = "[B]uffers" })
vim.keymap.set("n", "<leader>f/", function()
	-- You can pass additional configuration to telescope to change theme, layout, etc.
	require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 10,
		previewer = false,
	}))
end, { desc = "[F]uzzily [/]search in current buffer" })


require("which-key").register({
	g = {
		name = "Git", -- optional group name
	},
}, { prefix = "<leader>" })
vim.keymap.set("n", "<leader>gf", require("telescope.builtin").git_files, { desc = "[F]iles" })
vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "[F]iles" })
vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags, { desc = " [H]elp" })
vim.keymap.set("n", "<leader>fw", require("telescope.builtin").grep_string, { desc = "[W]ord" })
vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, { desc = "[G]rep" })
vim.keymap.set("n", "<leader>fd", require("telescope.builtin").diagnostics, { desc = "[D]iagnostics" })
