require('which-key').register {
  ['<leader>m'] = { name = '[M]arkdown', _ = 'which_key_ignore' },
}

require('which-key').register {
  ['<leader>mh'] = { name = '[H]eading', _ = 'which_key_ignore' },
}

vim.keymap.set('n', '<leader>mh1', 'i#<Esc>i', { desc = '[1]' })
vim.keymap.set('n', '<leader>mh2', '2i#<Esc>i', { desc = '[2]' })
vim.keymap.set('n', '<leader>mh3', '3i#<Esc>i', { desc = '[3]' })
vim.keymap.set('n', '<leader>mh4', '4i#<Esc>i', { desc = '[4]' })
vim.keymap.set('n', '<leader>mi', '2i*<Esc>i', { desc = '[I]talic' })
vim.keymap.set('n', '<leader>mb', '4i*<Esc>2<Left>a', { desc = '[B]old' })

vim.keymap.set('n', '<leader>mc', 'o- [ ] ', { desc = '[C]heckbox' })
vim.keymap.set('n', '<leader>mt', 'o| # | # | # |<Esc>o|----|----|----|<Esc>o| # | # | # |<Esc>2k0/#<CR>', { desc = '[T]able' })

require('which-key').register {
  ['<leader>ma'] = { name = '[A]rrow', _ = 'which_key_ignore' },
}
vim.keymap.set('n', '<leader>mal', 'a  -->  ', { desc = '[L] Right' })
vim.keymap.set('n', '<leader>mah', 'i  <--  <Esc>b2hi', { desc = '[H] Left' })
-- vim.keymap.set('n', '<leader>mak', 'i -marker- <Esc>yyP/-marker-<CR>ciW|-marker-<Esc>yyP/-marker-<CR>ciW^<Esc>:%s/-marker-//g<CR>2k', { desc = '[k] Up' })
