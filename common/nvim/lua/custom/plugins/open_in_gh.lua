return {
  'almo7aya/openingh.nvim',
  cmd = {
    'OpenInGHRepo',
    'OpenInGHFile',
    'OpenInGHFileLines',
  },
  init = function()
    -- for repository page
    vim.keymap.set('n', '<Leader>ggor', ':OpenInGHRepo <CR>', { desc = 'Open [R]epo' })

    -- for current file page
    vim.keymap.set('n', '<Leader>ggof', ':OpenInGHFile <CR>', { desc = 'Open [F]ile' })
    vim.keymap.set('n', '<Leader>ggol', ':OpenInGHFileLines <CR>', { desc = 'Open [F]ile' })
  end,
}
