-- FORMATTING
lvim.format_on_save.enabled = true
lvim.format_on_save.pattern = { '*' }
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  {
    -- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
    command = "eslint_d",
  },
  {
    name = "prettier",
    ---@usage arguments to pass to the formatter
    -- these cannot contain whitespace
    -- options such as `--line-width 80` become either `{"--line-width", "80"}` or `{"--line-width=80"}`
  },
  -- {
  --   command = "blade_formatter",
  --   filetypes = { "blade" },
  -- },
  -- {
  --   command = "phpcsfixer",
  -- }
  {
    command = "ruff",
  },
}

-- LINTING
local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  {
    -- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/builtins.md#configuration
    command = "eslint_d",
    ---@usage specify which filetypes to enable. by default a providers will attach to all the filetypes it supports.
  },
  -- {
  --   command = "phpcs",
  -- }
  {
    command = "ruff",
  },
}
-- CODE ACTIONS
local codeActions = require "lua.lvim.lsp.null-ls.code_actions"
codeActions.setup {
  {
    command = "eslint_d",
  },
  {
    command = "ruff",
  },
}

-- COMMANDS
lvim.builtin.which_key.mappings["l"]["f"] = {
  function()
    vim.lsp.format { timeout = 500 }
  end,
  "LSP format",
}

lvim.lsp.null_ls.setup.on_attach = function(client, bufnr)
  local lsp_format_modifications = require "lsp-format-modifications"
  lsp_format_modifications.attach(client, bufnr, { format_on_save = true })
end

print(lvim.lsp.null_ls.setup)
