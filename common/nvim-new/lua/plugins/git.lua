local gitsigns = {
  -- See `:help gitsigns` to understand what the configuration keys do
  -- Adds git related signs to the gutter, as well as utilities for managing changes
  "lewis6991/gitsigns.nvim",
  pin = true,
  opts = {
    -- signs = {
    -- 	add = { text = "+" },
    -- 	change = { text = "~" },
    -- 	delete = { text = "_" },
    -- 	topdelete = { text = "‾" },
    -- 	changedelete = { text = "~" },
    -- },

    on_attach = function(buffer)
      local gs = package.loaded.gitsigns

      require("which-key").add({
        { "<leader>gh", group = "hunk", desc = "LazyGit" },
      })
      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
      end

      map("n", "]h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, "Next Hunk")
      map("n", "[h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Prev Hunk")
      map("n", "]H", function()
        gs.nav_hunk("last")
      end, "Last Hunk")
      map("n", "[H", function()
        gs.nav_hunk("first")
      end, "First Hunk")
      map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
      map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
      map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
      map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
      map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
      map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
      map("n", "<leader>ghb", function()
        gs.blame_line({ full = true })
      end, "Blame Line")
      map("n", "<leader>ghB", function()
        gs.blame()
      end, "Blame Buffer")
      map("n", "<leader>ghd", gs.diffthis, "Diff This")
      map("n", "<leader>ghD", function()
        gs.diffthis("~")
      end, "Diff This ~")
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
    end,
  },
}

-- open lazygit in terminal
vim.keymap.set("n", "<leader>gg", "<Esc>:vsplit<CR><Esc>:terminal<CR>ilazygit<CR>", { desc = "LazyGit" })

local advancedGitSearch = {
  "aaronhallaert/advanced-git-search.nvim",
  pin = true,
  cmd = { "AdvancedGitSearch" },
  init = function()
    -- add keymaps
    require("which-key").add({ "<leader>ga", "which_key_ignore", desc = "advanced git search", mode = "n" })
    vim.keymap.set("n", "<Leader>gaf", "<Esc>:AdvancedGitSearch diff_commit_file<CR>", { desc = "file commits" })
    vim.keymap.set("v", "<Leader>gal", "<Esc>:AdvancedGitSearch diff_commit_line<CR>", { desc = "line commits" })

    require("telescope").load_extension("advanced_git_search")
  end,
  dependencies = {
    { "nvim-telescope/telescope.nvim", pin = true },
    { "tpope/vim-fugitive", pin = true },
    { "tpope/vim-rhubarb", pin = true },
    -- optional: to replace the diff from fugitive with diffview.nvim
    -- (fugitive is still needed to open in browser)
    { "sindrets/diffview.nvim", pin = true },
  },
}

local openInGithub = {
  "almo7aya/openingh.nvim",
  pin = true,
  cmd = {
    "OpenInGHRepo",
    "OpenInGHFile",
    "OpenInGHFileLines",
  },
  init = function()
    require("which-key").add(
      { "<leader>gH", "which_key_ignore", desc = "GitHub", mode = "n" },
      { "<leader>gHo", "which_key_ignore", desc = "open", mode = "n" }
    )

    -- for repository page
    vim.keymap.set("n", "<Leader>gHor", ":OpenInGHRepo <CR>", { desc = "Open [R]epo" })

    -- for current file page
    vim.keymap.set("n", "<Leader>gHof", ":OpenInGHFile <CR>", { desc = "Open [F]ile" })
    vim.keymap.set("n", "<Leader>gHol", ":OpenInGHFileLines <CR>", { desc = "Open [F]ile" })
  end,
}

return {
  gitsigns,
  -- lazygit,
  advancedGitSearch,
  openInGithub,
}
