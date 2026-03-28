-- Find best file finder command
local function find_command()
  if 1 == vim.fn.executable("rg") then
    return { "rg", "--files", "--color", "never", "-g", "!.git" }
  elseif 1 == vim.fn.executable("fd") then
    return { "fd", "--type", "f", "--color", "never", "-E", ".git" }
  elseif 1 == vim.fn.executable("fdfind") then
    return { "fdfind", "--type", "f", "--color", "never", "-E", ".git" }
  elseif 1 == vim.fn.executable("find") and vim.fn.has("win32") == 0 then
    return { "find", ".", "-type", "f" }
  elseif 1 == vim.fn.executable("where") then
    return { "where", "/r", ".", "*" }
  end
end

return { -- Fuzzy Finder (files, lsp, etc)
  "nvim-telescope/telescope.nvim",
  pin = true,
  event = "VimEnter",
  branch = "master",
  dependencies = {
    { "nvim-lua/plenary.nvim", pin = true },
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      pin = true,
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
    { "nvim-telescope/telescope-ui-select.nvim", pin = true },
    { "nvim-tree/nvim-web-devicons", pin = true, enabled = vim.g.have_nerd_font },
  },
  keys = {
    -- Files
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    { "<leader><space>", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
    {
      "<leader>fb",
      "<cmd>Telescope buffers sort_mru=true sort_lastused=true ignore_current_buffer=true<cr>",
      desc = "Buffers",
    },
    { "<leader>fr", "<cmd>Telescope resume<cr>", desc = "Resume" },

    -- Search
    { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Help Pages" },
    { "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "Document Diagnostics" },
    { "<leader>sD", "<cmd>Telescope diagnostics<cr>", desc = "Workspace Diagnostics" },
    {
      "<leader>ss",
      function()
        require("telescope.builtin").lsp_document_symbols()
      end,
      desc = "Document Symbols",
    },
    {
      "<leader>sS",
      function()
        require("telescope.builtin").lsp_dynamic_workspace_symbols()
      end,
      desc = "Workspace Symbols",
    },

    -- Git
    { "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Git Commits" },
    { "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "Git Status" },
  },
  config = function()
    local actions = require("telescope.actions")
    local open_with_trouble = function()
      return vim.cmd.Trouble("telescope")
    end

    require("telescope").setup({
      defaults = {
        mappings = {
          i = {
            ["<c-t>"] = open_with_trouble,
            ["<a-t>"] = open_with_trouble,
            ["<C-Down>"] = actions.cycle_history_next,
            ["<C-Up>"] = actions.cycle_history_prev,
            ["<C-f>"] = actions.preview_scrolling_down,
            ["<C-b>"] = actions.preview_scrolling_up,
            ["<c-r>"] = "to_fuzzy_refine",
          },
          n = {
            ["q"] = actions.close,
          },
        },
      },
      pickers = {
        find_files = {
          find_command = find_command(),
          hidden = false,
          no_ignore = false,
        },
      },
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
        fzf = {},
      },
    })

    pcall(require("telescope").load_extension, "fzf")
    pcall(require("telescope").load_extension, "ui-select")
    pcall(require("telescope").load_extension("neoclip"))
  end,
}
