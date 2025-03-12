return {
  {
    "stevearc/conform.nvim",
    dependencies = { "mason.nvim" },
    lazy = true,
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format { formatters = { "injected" }, timeout_ms = 3000 }
        end,
        mode = { "n", "v" },
        desc = "Format Injected Langs",
      },
      {
        "<leader>cf",
        function()
          require("conform").format { async = false, lsp_fallback = true }
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
    init = function()
      -- Initialize autoformat flag

      -- Create a Format command
      vim.api.nvim_create_user_command("Format", function(args)
        local range = nil
        if args.count ~= -1 then
          range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, 0 },
          }
        end
        require("conform").format { async = false, lsp_fallback = true, range = range }
      end, { range = true })

      -- Create autocmd for format on save
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("ConformFormatOnSave", { clear = true }),
        callback = function(args)
          -- Skip formatting if disabled
          if vim.b.disable_autoformat then
            return
          end
          require("conform").format {
            bufnr = args.buf,
            async = false,
            lsp_fallback = true,
          }
        end,
      })
    end,
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        fish = { "fish_indent" },
        sh = { "shfmt" },
      },
      formatters = {
        injected = { options = { ignore_errors = true } },
        stylua = {
          prepend_args = {
            "--indent-type",
            "Spaces",
            "--indent-width",
            "2",
            "--column-width",
            "120",
            "--quote-style",
            "AutoPreferDouble",
            "--call-parentheses",
            "None",
          },
        },
      },
    },
  },
}
