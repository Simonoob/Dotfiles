return {
  "almo7aya/openingh.nvim",
  cmd = {
    "OpenInGHRepo",
    "OpenInGHFile",
    "OpenInGHFileLines",
  },
  init = function()
    require("which-key").add(
      { "<leader>gH", "which_key_ignore", desc = "GitHub", mode = "n" },
      { "<leader>gHo", "which_key_ignore", desc = "open", mode = "n" }
    )

    -- for repository page
    vim.keymap.set("n", "<Leader>gHor", ":OpenInGHRepo <CR>", { desc = "Open [R]epo" })

    -- for current file page
    vim.keymap.set("n", "<Leader>gHof", ":OpenInGHFile <CR>", { desc = "Open [F]ile" })
    vim.keymap.set("n", "<Leader>gHol", ":OpenInGHFileLines <CR>", { desc = "Open [F]ile" })
  end,
}
