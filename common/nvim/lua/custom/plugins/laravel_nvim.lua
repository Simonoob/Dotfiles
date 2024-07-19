return {
  'adalessa/laravel.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'tpope/vim-dotenv',
    'MunifTanjim/nui.nvim',
    'nvimtools/none-ls.nvim',
  },
  cmd = { 'Sail', 'Artisan', 'Composer', 'Npm', 'Yarn', 'Laravel' },
  keys = {},
  event = { 'VeryLazy' },
  setup = {
    features = {
      null_ls = {
        enable = false,
      },
    },
  },
  config = function(_, setupObj)
    require('laravel').setup(setupObj)
    require('which-key').register {
      ['<leader>.'] = { name = '[.] Second layer kaymaps', _ = 'which_key_ignore' },
    }
    require('which-key').register {
      ['<leader>.l'] = { name = '[L]aravel', _ = 'which_key_ignore' },
    }
    vim.keymap.set('n', '<leared>.la', ':Laravel artisan<CR>', { desc = '[A]rtisan' })
    vim.keymap.set('n', '<leared>.lr', ':Laravel routes<CR>', { desc = '[R]outes' })
    vim.keymap.set('n', '<leared>.lm', ':Laravel related<CR>', { desc = '[M] related' })
  end,
}
