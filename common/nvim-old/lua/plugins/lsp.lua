return {
	-- LSP Configuration
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			-- Set up diagnostics icons
			local icons = {
				diagnostics = {
					Error = " ",
					Warn = " ",
					Hint = " ",
					Info = " ",
				},
			}

			-- Configure diagnostics
			vim.diagnostic.config({
				underline = true,
				update_in_insert = false,
				virtual_text = {
					spacing = 4,
					source = "if_many",
					prefix = "●",
				},
				severity_sort = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
						[vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
						[vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
						[vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
					},
				},
			})

			-- Configure diagnostics signs for Neovim < 0.10.0
			if vim.fn.has("nvim-0.10.0") == 0 then
				for severity, icon in pairs(icons.diagnostics) do
					local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
					name = "DiagnosticSign" .. name
					vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
				end
			end

			-- Setup LSP keymaps
			local on_attach = function(client, bufnr)
				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "LSP: " .. desc })
				end

				-- LSP actions
				map("n", "gd", vim.lsp.buf.definition, "Goto Definition")
				map("n", "gr", vim.lsp.buf.references, "Goto References")
				map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
				map("n", "gI", vim.lsp.buf.implementation, "Goto Implementation")
				map("n", "gt", vim.lsp.buf.type_definition, "Goto Type Definition")
				map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
				map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
				map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
				map("n", "<leader>cR", vim.lsp.buf.rename, "Rename")
				map("n", "<leader>cf", function()
					vim.lsp.buf.format({ async = true })
				end, "Format Document")

				-- Diagnostics
				map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostics")
				map("n", "[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
				map("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
				map("n", "<leader>cq", vim.diagnostic.setloclist, "Diagnostics List")

				-- CodeLens (Neovim >= 0.10.0)
				if vim.fn.has("nvim-0.10") == 1 and client.server_capabilities.codeLensProvider then
					map("n", "<leader>cl", vim.lsp.codelens.run, "Run CodeLens")
					vim.lsp.codelens.refresh()
					vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
						buffer = bufnr,
						callback = vim.lsp.codelens.refresh,
					})
				end

				-- Inlay hints (Neovim >= 0.10.0)
				if vim.fn.has("nvim-0.10") == 1 and client.server_capabilities.inlayHintProvider then
					local ft = vim.bo[bufnr].filetype
					if
						vim.api.nvim_buf_is_valid(bufnr)
						and vim.bo[bufnr].buftype == ""
						and not vim.tbl_contains({ "vue" }, ft)
					then
						vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
					end
				end
			end

			-- Build LSP capabilities
			local capabilities = vim.lsp.protocol.make_client_capabilities()

			-- Add cmp_nvim_lsp capabilities if available
			local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
			if has_cmp then
				capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
			end

			-- Add workspace capabilities
			capabilities.workspace = {
				fileOperations = {
					didRename = true,
					willRename = true,
				},
			}

			-- Configure servers
			local servers = {
				lua_ls = {
					settings = {
						Lua = {
							workspace = {
								checkThirdParty = false,
							},
							codeLens = {
								enable = true,
							},
							completion = {
								callSnippet = "Replace",
							},
							doc = {
								privateName = { "^_" },
							},
							hint = {
								enable = true,
								setType = false,
								paramType = true,
								paramName = "Disable",
								semicolon = "Disable",
								arrayIndex = "Disable",
							},
						},
					},
				},
				-- Add other servers as needed
			}

			-- Configure lspconfig with mason-lspconfig
			local mason_lspconfig = require("mason-lspconfig")

			mason_lspconfig.setup({
				ensure_installed = {
					"lua_ls",
					-- Add other servers to install here
					"eslint",
					"vtsls",
				},
			})

			mason_lspconfig.setup_handlers({
				function(server_name)
					local server_opts = vim.tbl_deep_extend("force", {
						capabilities = capabilities,
						on_attach = on_attach,
					}, servers[server_name] or {})

					require("lspconfig")[server_name].setup(server_opts)
				end,
			})
		end,
	},

	-- Mason for installing LSP servers, formatters, etc.
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		opts = {
			ensure_installed = {
				"stylua",
				"shfmt",
				"prettierd",
				"prettier",
			},
		},
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")

			-- Install configured tools
			mr.refresh(function()
				for _, tool in ipairs(opts.ensure_installed or {}) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end)
		end,
	},
}
