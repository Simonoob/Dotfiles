return {
  'almo7aya/openingh.nvim',
  cmd = {
    'OpenInGHRepo',
    'OpenInGHFile',
    'OpenInGHFileLines',
  },
  init = function()
    print 'going through the config function'
    -- for repository page
    vim.keymap.set('n', '<Leader>ggr', ':OpenInGHRepo <CR>', { desc = 'Open [R]epo' })

    -- for current file page
    vim.keymap.set('n', '<Leader>ggf', ':OpenInGHFile <CR>', { desc = 'Open [F]ile' })
    vim.keymap.set('n', '<Leader>ggl', ':OpenInGHFileLines <CR>', { desc = 'Open [F]ile' })
  end,
}
