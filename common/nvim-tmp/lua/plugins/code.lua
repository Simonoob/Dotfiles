local formatting = { -- Autoformat
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {

		{
			"<leader>cF",
			function()
				require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
			end,
			mode = { "n", "v" },
			desc = "Format Injected Langs",
		},
		{
			"<leader>cf",
			function()
				require("conform").format({ async = false, lsp_fallback = true })
			end,
			mode = "n",
			desc = "Format Document",
		},
		{
			"<leader>ct",
			function()
				if vim.b.disable_autoformat then
					-- Enable format
					vim.b.disable_autoformat = false
					vim.notify("Autoformat enabled", vim.log.levels.INFO)
				else
					-- Disable format
					vim.b.disable_autoformat = true
					vim.notify("Autoformat disabled (buffer)", vim.log.levels.INFO)
				end
			end,
			mode = "n",
			desc = "Toggle Format on Save",
		},
	},
	opts = {
		notify_on_error = true,
		default_format_opts = {
			timeout = 2000,
		},
		format_on_save = function(bufnr)
			-- Skip formatting if disabled
			if vim.b.disable_autoformat then
				return
			end

			-- Disable "format_on_save lsp_fallback" for languages that don't
			-- have a well standardized coding style. You can add additional
			-- languages here or re-enable it for the disabled ones.
			local disable_filetypes = { c = true, cpp = true }
			local lsp_format_opt
			if disable_filetypes[vim.bo[bufnr].filetype] then
				lsp_format_opt = "never"
			else
				lsp_format_opt = "fallback"
			end

			return {
				lsp_format = lsp_format_opt,
			}
		end,
		formatters_by_ft = {
			lua = { "stylua" },
			-- Conform can also run multiple formatters sequentially
			-- python = { "isort", "black" },
			--
			-- You can use 'stop_after_first' to run the first available formatter from the list
			javascript = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
		},
	},
}

local lua_snip = {
	-- Snippet Engine & its associated nvim-cmp source
	"L3MON4D3/LuaSnip",
	build = (function()
		-- Build Step is needed for regex support in snippets.
		-- This step is not supported in many windows environments.
		-- Remove the below condition to re-enable on windows.
		if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
			return
		end
		return "make install_jsregexp"
	end)(),
	dependencies = {
		-- `friendly-snippets` contains a variety of premade snippets.
		--    See the README about individual language/framework/plugin snippets:
		--    https://github.com/rafamadriz/friendly-snippets
		{
			"rafamadriz/friendly-snippets",
			config = function()
				require("luasnip.loaders.from_vscode").lazy_load()
			end,
		},
	},
	opts = {
		history = true,
		delete_check_events = "TextChanged",
	},
}

local autocomplete = {
	"hrsh7th/nvim-cmp",
	dependencies = {
		lua_snip,
		"saadparwaiz1/cmp_luasnip",

		-- Adds other completion capabilities.
		--  nvim-cmp does not ship with all sources by default. They are split
		--  into multiple repos for maintenance purposes.
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-nvim-lsp-signature-help",
	},
	config = function()
		-- See `:help cmp`
		local cmp = require("cmp")
		local luasnip = require("luasnip")
		luasnip.config.setup({})

		cmp.setup({
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			completion = { completeopt = "menu,menuone,noinsert" },

			-- For an understanding of why these mappings were
			-- chosen, you will need to read `:help ins-completion`
			--
			-- No, but seriously. Please read `:help ins-completion`, it is really good!
			mapping = cmp.mapping.preset.insert({
				-- Navigate between snippet placeholder
				["<C-d>"] = cmp.mapping.scroll_docs(-4),
				["<C-u>"] = cmp.mapping.scroll_docs(4),
				["<C-e>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({ select = true }),
				["<S-CR>"] = cmp.mapping.confirm({
					behavior = cmp.ConfirmBehavior.Replace,
					select = true,
				}),
				["<C-CR>"] = function(fallback)
					cmp.abort()
					fallback()
				end,
				-- Use Tab for completion confirmation and snippet navigation
				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.confirm({ select = true })
					elseif luasnip.expand_or_jumpable() then
						luasnip.expand_or_jump()
					else
						fallback()
					end
				end, { "i", "s" }),
				["<S-Tab>"] = cmp.mapping(function(fallback)
					if luasnip.jumpable(-1) then
						luasnip.jump(-1)
					else
						fallback()
					end
				end, { "i", "s" }),
				-- Navigate between completion items
				["<C-j>"] = cmp.mapping.select_next_item(),
				["<C-k>"] = cmp.mapping.select_prev_item(),

				-- Manually trigger a completion from nvim-cmp.
				--  Generally you don't need this, because nvim-cmp will display
				--  completions whenever it has completion options available.
				["<C-Space>"] = cmp.mapping.complete({}),
			}),
			sources = {
				{
					name = "lazydev",
					-- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
					group_index = 0,
				},
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "buffer" },
				{ name = "path" },
				{ name = "nvim_lsp_signature_help" },
			},
			experimental = {
				ghost_text = {
					hl_group = "CmpGhostText",
				},
			},
		})
	end,
}

local treesitter = { -- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	main = "nvim-treesitter.configs", -- Sets main module to use for opts
	-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
	opts = {
		ensure_installed = {
			"bash",
			"c",
			"diff",
			"html",
			"lua",
			"luadoc",
			"markdown",
			"markdown_inline",
			"query",
			"vim",
			"vimdoc",
		},
		-- Autoinstall languages that are not installed
		auto_install = true,
		highlight = {
			enable = true,
			-- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
			--  If you are experiencing weird indenting issues, add the language to
			--  the list of additional_vim_regex_highlighting and disabled languages for indent.
			additional_vim_regex_highlighting = { "ruby" },
		},
		indent = { enable = true, disable = { "ruby" } },
	},
	-- There are additional nvim-treesitter modules that you can use to interact
	-- with nvim-treesitter. You should go explore a few and see what interests you:
	--
	--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
	--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
	--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
}

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

return {
	treesitter,
	auto_detect_tabs,
	formatting,
	autocomplete,
	auto_pairs,
}
