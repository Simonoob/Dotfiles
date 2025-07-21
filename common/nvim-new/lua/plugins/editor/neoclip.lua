return {
  -- clipboard managment with telescope integration
  "AckslD/nvim-neoclip.lua",
  pin = true,
  dependencies = {
    { "nvim-telescope/telescope.nvim", pin = true },
    { "kkharji/sqlite.lua", pin = true, module = "sqlite" }, -- for persistent storage across sessions
  },
  config = function()
    require("neoclip").setup()
    vim.keymap.set({ "n" }, "<leader>sr", "<cmd>Telescope neoclip plus<cr>", { desc = "Registers ( `+` )" })
  end,
}
