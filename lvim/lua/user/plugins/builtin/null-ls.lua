-- FORMATTING
lvim.format_on_save.enabled = true
lvim.format_on_save.pattern = { '*' }
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  {
    command = "eslint",
  },
  {
    command = "prettierd",
  },
  {
    command = "blade_formatter",
    filetypes = { "blade" },
  },
  {
    command = "phpcsfixer",
  }
}

-- LINTING
local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  {
    -- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
    command = "eslint",
    ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
  },
  {
    command = "phpcs",
  }
}
