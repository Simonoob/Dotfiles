return {
  "mfussenegger/nvim-lint",
  event = "LazyFile",
  opts = function(_, opts)
    opts.linters_by_ft.php = { "tlint" }
  end,
}
