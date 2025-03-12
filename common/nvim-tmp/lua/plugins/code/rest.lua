local auto_pairs = {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	config = function()
		require("nvim-autopairs").setup({})
		-- If you want to automatically add `(` after selecting a function or method
		local cmp_autopairs = require("nvim-autopairs.completion.cmp")
		local cmp = require("cmp")
		cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
	end,
}

local auto_detect_tabs = {
	"tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically
}

local inc_rename = {
	"smjonas/inc-rename.nvim",
	config = function()
		require("inc_rename").setup()
	end,
	keys = {
		{
			mode = { "n" },
			"<leader>cr",
			function()
				return ":IncRename " .. vim.fn.expand("<cword>")
			end,
			expr = true,
			desc = "Rename (inc-rename.nvim)",
		},
	},
}

return {
	auto_detect_tabs,
	auto_pairs,
	inc_rename,
}
