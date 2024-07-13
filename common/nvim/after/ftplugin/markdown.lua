-- UTILS --------------------------
local function write_at_cursor(text)
  local column_pos = vim.api.nvim_win_get_cursor(0)[2]
  local current_line = vim.api.nvim_get_current_line()
  local nline = current_line:sub(0, column_pos) .. text .. current_line:sub(column_pos + 1)
  vim.api.nvim_set_current_line(nline)
end

local function write_above_cursor(text, new_line)
  new_line = new_line or true
  local column_pos = vim.api.nvim_win_get_cursor(0)[2]
  local line_num = vim.api.nvim_win_get_cursor(0)[1]

  if new_line then
    local nline = string.rep(' ', column_pos) .. text
    vim.api.nvim_buf_set_lines(0, line_num - 1, line_num - 1, false, { nline })
  else
    local prev_line = vim.api.nvim_buf_get_lines(0, line_num - 2, line_num - 1, false)[1]
    local nline = prev_line:sub(0, column_pos) .. text .. prev_line:sub(column_pos + 1)
    vim.api.nvim_set_current_line(nline)
  end
  vim.api.nvim_win_set_cursor(0, { line_num, column_pos })
end
-- END UTILS --------------------------

local function write_below_cursor(text, new_line)
  new_line = new_line or true
  local column_pos = vim.api.nvim_win_get_cursor(0)[2]
  local line_num = vim.api.nvim_win_get_cursor(0)[1]

  if new_line then
    local nline = string.rep(' ', column_pos) .. text
    vim.api.nvim_buf_set_lines(0, line_num + 1, line_num + 1, false, { nline })
  else
    local next_line = vim.api.nvim_buf_get_lines(0, line_num + 1, line_num + 2, false)[1]
    local nline = next_line:sub(0, column_pos) .. text .. next_line:sub(column_pos + 1)
    vim.api.nvim_set_current_line(nline)
  end
  vim.api.nvim_win_set_cursor(0, { line_num + 1, column_pos })
end

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

vim.keymap.set('n', '<leader>mt', function()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_win_set_cursor(0, { line_num, 0 })
  write_below_cursor '| fill_heading | fill_heading | fill_heading |'
  write_below_cursor '|--------|--------|--------|'
  write_below_cursor '| fill_cell | fill_cell | fill_cell |'
  vim.cmd [[/fill\w*]]
end, { desc = '[T]able' })

require('which-key').register {
  ['<leader>ma'] = { name = '[A]rrow', _ = 'which_key_ignore' },
}
vim.keymap.set('n', '<leader>mal', 'a  -->  <Esc>', { desc = '[L] Right' })
vim.keymap.set('n', '<leader>mah', 'i  <--  <Esc>b2h', { desc = '[H] Left' })
vim.keymap.set('n', '<leader>mak', function()
  write_above_cursor '|'
  write_above_cursor '^'
end, { desc = '[K] Up' })
vim.keymap.set('n', '<leader>maj', function()
  write_below_cursor '|'
  write_below_cursor 'v'
end, { desc = '[J] Down' })
