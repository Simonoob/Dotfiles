-- TELESCOPE
lvim.builtin.which_key.mappings["f"] = {
  name = "find",
  f = { "<cmd>Telescope find_files<cr>", "files" },
  b = { "<cmd>Telescope buffers<cr>", "buffers" },
  w = { "<cmd>Telescope live_grep<cr>", "word" },
  h = { "<cmd>Telescope oldfiles<cr>", "word in history" },
  g = {
    ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
    'live grep'
  }
}
lvim.builtin.which_key.mappings["s"] = {
  lvim.builtin.which_key.mappings['s'],
  r = { "%:s/foo/bar/gc", "replace" }
}

-- BUFFERS
lvim.builtin.which_key.mappings["bc"] = { "<cmd>BufferKill<cr>", "Close current" }
lvim.builtin.which_key.mappings["bo"] = {
  "<cmd>BufferLineCloseLeft<cr><cmd>BufferLineCloseRight<cr>", "Close other"
}
