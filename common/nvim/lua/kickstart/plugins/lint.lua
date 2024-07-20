-- linting
return {
  'mfussenegger/nvim-lint',
  dependencies = {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
  },
  event = { 'BufReadPre', 'BufWritePost' },
  init = function()
    local lint = require 'lint'

    vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'BufEnter', 'BufReadPre', 'BufWritePost', 'CursorHold', 'CursorHoldI' }, {
      callback = function()
        lint.try_lint()
      end,
    })
  end,
  config = function()
    local lint = require 'lint'
    local phpcs = require('lint').linters.phpcs

    phpcs.args = {
      '-q',
      -- <- Add a new parameter here
      '--standard=PSR12',
      '--report=json',
      '-',
    }

    lint.linters_by_ft = {
      lua = { 'luacheck' },
      javascript = { 'eslint_d', 'eslint' },
      typescript = { 'eslint_d', 'eslint' },
      javascriptreact = { 'eslint_d', 'eslint' },
      typescriptreact = { 'eslint_d', 'eslint' },
      -- sh = { 'shellcheck' },
      -- fish = { 'fish' },
      json = { 'jsonlint' },
      markdown = { 'markdownlint', 'vale' },
      php = { 'php', 'phpcs' },
      css = { 'stylelint' },
      yaml = { 'yamllint' },
    }
  end,
}
