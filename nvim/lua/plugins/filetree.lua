local function on_attach(bufnr)
	local api = require("nvim-tree.api")
	local function opts(desc)
		return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
	end
	api.config.mappings.default_on_attach(bufnr) -- default mappings
	vim.keymap.set("n", "l", api.node.open.edit, opts("open"))
	vim.keymap.set("n", "h", api.node.navigate.parent_close, opts("close"))
end

return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local api = require("nvim-tree.api")
		require("nvim-tree").setup({
			sort_by = "case_sensitive",
			view = { width = 30 },
			renderer = { group_empty = true },
			filters = { dotfiles = true },
			on_attach = on_attach,
		})

		vim.keymap.set("n", "<leader>e", function()
			local currentFilePath = vim.fn.expand("%:p") -- might be empty
			api.tree.toggle({ find_file = true, focus = true, path = currentFilePath, update_root = false })
		end, { desc = "[E]xpore file tree" })
	end,
}
