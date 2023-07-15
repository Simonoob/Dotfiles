local telescope = lvim.builtin.telescope

telescope.theme = "center"

telescope.pickers = {
  find_files = {
    hidden = true,
  },
  buffers = {
    previewer = false,
    layout_config = {
      width = 80,
    },
  },
  oldfiles = {
    prompt_title = 'History',
  },
}


telescope.defaults = {
  path_display = { truncate = 1 },
  prompt_prefix = '   ',
  selection_caret = '  ',
  layout_strategy = 'flex',
  layout_config = {
    prompt_position = "top",
  },
  sorting_strategy = 'ascending',
  mappings = {
    i = {
      -- ['<esc>'] = actions.close,
      -- ['<C-Down>'] = actions.cycle_history_next,
      -- ['<C-Up>'] = actions.cycle_history_prev,
    },
  },
  file_ignore_patterns = { '.git/' },
}
