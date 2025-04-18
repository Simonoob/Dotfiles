return {
  -- clipboard managment with telescope integration
  "AckslD/nvim-neoclip.lua",
  dependencies = {
    { "nvim-telescope/telescope.nvim" },
    { "kkharji/sqlite.lua", module = "sqlite" }, -- for persistent storage across sessions
  },
  config = function()
    require("neoclip").setup()
    vim.keymap.set({ "n" }, "<leader>sr", "<cmd>Telescope neoclip plus<cr>", { desc = "Registers ( `+` )" })
  end,
}
