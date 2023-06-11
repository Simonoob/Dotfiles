-- TELESCOPE
lvim.builtin.which_key.mappings["f"] = {
  name = "find",
  f = { "<cmd>Telescope find_files<cr>", "files" },
  b = { "<cmd>Telescope buffers<cr>", "buffers" },
  w = { "<cmd>Telescope live_grep<cr>", "grep" },
  h = { "<cmd>Telescope oldfiles<cr>", "grep" },
}

-- BUFFERS
lvim.builtin.which_key.mappings["bc"] = { "<cmd>BufferKill<cr>", "Close current" }
lvim.builtin.which_key.mappings["bo"] = { "<cmd>BufferLineCloseLeft<cr><cmd>BufferLineCloseRight<cr>", "Close other" }
