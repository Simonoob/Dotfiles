return {
  "ray-x/navigator.lua",
  enabled = false,
  dependencies = {
    {
      "ray-x/guihua.lua",
      build = "cd lua/fzy && make",
    },
    "neovim/nvim-lspconfig",
    { "williamboman/mason.nvim", opts = {} },
    "williamboman/mason-lspconfig.nvim", -- compatibility layer for mason and lspconfig
    "WhoIsSethDaniel/mason-tool-installer.nvim", -- handles updates for tools installed via mason
  },
  config = function()
    print("Loading navigator.lua")
    local module = require("navigator")
    module.setup({ mason = true })

    vim.keymap.set("n", "<leader>rn", module.name, { desc = "Rename" })
    vim.keymap.set("n", "<leader>ca", module.code_action, { desc = "Code Action" })
    vim.keymap.set("n", "<leader>gd", module.definition, { desc = "Go to Definition" })
    vim.keymap.set("n", "<leader>gr", module.reference, { desc = "Go to Reference" })
  end,
}
