return { -- Autoformat
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
        require("conform").format({ async = true, lsp_fallback = true })
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
      timeout = 3000,
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
      python = { "ruff_fix", "ruff_format" },
      --
      -- You can use 'stop_after_first' to run the first available formatter from the list
      javascript = { "eslint_d", "prettierd" },
      typescript = { "eslint_d", "prettierd" },
      javascriptreact = { "eslint_d", "prettierd" },
      typescriptreact = { "eslint_d", "prettierd" },
    },
  },
}
