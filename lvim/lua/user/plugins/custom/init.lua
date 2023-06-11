lvim.plugins = {
  { 'jwalton512/vim-blade' },
  {
    'zbirenbaum/copilot.lua',
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("user/plugins/custom/copilot")
    end,
  },
}
