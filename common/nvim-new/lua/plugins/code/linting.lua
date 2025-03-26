local active_events = {
	-- "BufWritePost", "BufReadPost", "InsertLeave",
	"TextChanged", -- run on all text changes
}
return {
	{
		"mfussenegger/nvim-lint",
		enabled = false, -- gave issues with updates - I already have the Eslint LSP server, do I really need this?
		event = active_events,
		config = function()
			local lint = require("lint")

			-- Configure linters by filetype
			lint.linters_by_ft = {
				fish = { "fish" },
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				-- Use the "*" filetype to run linters on all filetypes
				-- ['*'] = { 'global linter' },
				-- Use the "_" filetype to run linters on filetypes that don't have other linters configured
				-- ['_'] = { 'fallback linter' },
			}

			-- Custom linter configurations
			-- Example: lint.linters.selene = { ... custom config ... }

			-- Define a debounce function
			local function debounce(ms, fn)
				local timer = vim.uv.new_timer()
				return function(...)
					local argv = { ... }
					timer:start(ms, 0, function()
						timer:stop()
						vim.schedule_wrap(fn)(unpack(argv))
					end)
				end
			end

			-- Define the lint function
			local function do_lint()
				lint.try_lint()
			end

			-- Setup autocmd to trigger linting
			vim.api.nvim_create_autocmd(active_events, {
				group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
				callback = debounce(100, do_lint),
			})
		end,
	},
}
