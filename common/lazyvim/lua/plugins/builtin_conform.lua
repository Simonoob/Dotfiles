local util = require("conform.util")
return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.default_format_opts = {
      timeout_ms = 1000,
      async = false, -- not recommended to change
      quiet = false, -- not recommended to change
    }

    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.php = { "pint" }
    opts.formatters_by_ft.blade = { "tlint", "rustywind" }

    opts.formatters = opts.formatters or {}
    opts.formatters.pint = {
      meta = {
        url = "https://github.com/laravel/pint",
        description = "Laravel Pint is an opinionated PHP code style fixer for minimalists. Pint is built on top of PHP-CS-Fixer and makes it simple to ensure that your code style stays clean and consistent.",
      },
      command = util.find_executable({
        vim.fn.stdpath("data") .. "/mason/bin/pint",
        "vendor/bin/pint",
      }, "pint"),
      args = { "$FILENAME" },
      stdin = false,
    }

    return opts
  end,
}
