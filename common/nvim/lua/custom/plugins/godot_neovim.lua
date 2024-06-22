--[[ allows good indenting and starting scenes directly with commands
check the GH page for the commands ]]

return {
  'upperhands/godot-neovim',
  event = 'VimEnter',

  config = function()
    local godotNeovim = require('godot-neovim').setup {

      godot_executable = 'C:/Users/eleon/Downloads/Godot_v4.2.2-stable_win64.exe/Godot_v4.2.2-stable_win64.exe', -- path to godot executable, can be an alias in user shell
      use_default_keymaps = false,
    }

    local file_exists = function(file_path)
      return vim.fn.filereadable(file_path) ~= 0
    end
    local is_godot_project = file_exists(vim.fn.getcwd() .. '/project.godot')

    if is_godot_project then
      require('which-key').register {
        ['<leader>G'] = { name = '[G]odot', _ = 'which_key_ignore' },
        ['<leader>Gr'] = { name = '[R]un scene', _ = 'which_key_ignore' },
      }
      vim.keymap.set('n', '<Leader>Grm', ':GdRunMainScene <CR>', { desc = '[M]ain scene' })
      vim.keymap.set('n', '<Leader>Grl', ':GdRunLastScene <CR>', { desc = '[L]ast scene' })
      vim.keymap.set('n', '<Leader>Grs', ':GdRunSelectScene <CR>', { desc = '[S]elect scene' })
    end
  end,
}
