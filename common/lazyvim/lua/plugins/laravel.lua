return {
  "adalessa/laravel.nvim",
  dependencies = {
    "tpope/vim-dotenv",
    "nvim-telescope/telescope.nvim",
    "MunifTanjim/nui.nvim",
    "kevinhwang91/promise-async",
  },
  cmd = { "Sail", "Artisan", "Composer", "Npm", "Yarn", "Laravel" },
  keys = {
    { "<leader>_la", ":Laravel artisan<cr>" },
    { "<leader>_lr", ":Laravel routes<cr>" },
    { "<leader>_lm", ":Laravel related<cr>" },
  },
  event = { "VeryLazy" },
  config = true,
}
