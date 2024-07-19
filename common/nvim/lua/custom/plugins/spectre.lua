-- on MacOS remember to brew install gnu-sed
return {
  'nvim-pack/nvim-spectre',
  opts = {
    is_block_ui_break = true,
  },
  config = function(_, opts)
    require('spectre').setup(opts)
    local spectre = require 'spectre'

    vim.keymap.set('n', '<leader>sp', spectre.toggle, { desc = 'in [P]roject' })
  end,
}
