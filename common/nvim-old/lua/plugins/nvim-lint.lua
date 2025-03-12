return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufWritePost", "BufReadPost", "InsertLeave" },
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
				-- Get linters for current filetype
				local names = lint._resolve_linter_by_ft(vim.bo.filetype)

				-- Create a copy of the names table
				names = vim.list_extend({}, names)

				-- Add fallback linters if no linters found
				if #names == 0 then
					vim.list_extend(names, lint.linters_by_ft["_"] or {})
				end

				-- Add global linters
				vim.list_extend(names, lint.linters_by_ft["*"] or {})

				-- Filter out linters that don't exist or don't match the condition
				local ctx = { filename = vim.api.nvim_buf_get_name(0) }
				ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
				names = vim.tbl_filter(function(name)
					local linter = lint.linters[name]
					if not linter then
						vim.notify("Linter not found: " .. name, vim.log.levels.WARN)
						return false
					end
					return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
				end, names)

				-- Run linters
				if #names > 0 then
					lint.try_lint(names)
				end
			end

			-- Setup autocmd to trigger linting
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
				group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
				callback = debounce(100, do_lint),
			})
		end,
	},
}
