return {
  "ray-x/navigator.lua",
  pin = true,
  enabled = false,
  dependencies = {
    {
      "ray-x/guihua.lua",
      pin = true,
      build = "cd lua/fzy && make",
    },
    { "neovim/nvim-lspconfig", pin = true },
    { "williamboman/mason.nvim", pin = true, opts = {} },
    { "williamboman/mason-lspconfig.nvim", pin = true },
    { "WhoIsSethDaniel/mason-tool-installer.nvim", pin = true },
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
