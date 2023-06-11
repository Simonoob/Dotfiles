-- TELESCOPE
lvim.builtin.which_key.mappings["f"] = {
  name = "find",
  f = { "<cmd>telescope find_files<cr>", "files" },
  b = { "<cmd>telescope buffers<cr>", "buffers" },
  w = { "<cmd>telescope live_grep<cr>", "grep" },
}

-- BUFFERS
lvim.builtin.which_key.mappings["bc"] = { "<cmd>BufferKill<cr>", "Close current" }
lvim.builtin.which_key.mappings["bo"] = { "<cmd>BufferLineCloseLeft<cr><cmd>BufferLineCloseRight<cr>", "Close other" }
