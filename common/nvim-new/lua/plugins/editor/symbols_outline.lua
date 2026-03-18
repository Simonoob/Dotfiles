return {
  "stevearc/aerial.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>cs", "<cmd>AerialToggle!<cr>", desc = "Toggle Outline" },
  },
  cmd = "AerialToggle",
  opts = {
    attach_mode = "window",
    nerd_font = true,
    keymaps = {
      ["<up>"] = "actions.scroll",
      ["<down>"] = "actions.scroll",
    },
    on_attach = function(bufnr)
      -- Jump forwards/backwards with '{' and '}'
      vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
      vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
    end,
  },
}
