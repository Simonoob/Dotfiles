return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = function(_, opts)
    vim.keymap.set("n", "<leader>si", function()
      require("telescope.builtin").live_grep({ additional_args = { "--hidden", "--no-ignore" } })
    end, { desc = "grep ignored & hidden files" })

    vim.keymap.set("n", "<leader>fi", function()
      require("telescope.builtin").find_files({
        hidden = true,
        no_ignore = true,
      })
    end, { desc = "find ignored & hidden files" })
  end,
}
