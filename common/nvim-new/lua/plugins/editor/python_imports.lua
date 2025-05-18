return {
  {
    "alexpasmantier/pymple.nvim",
    dir = "~/coding/pymple.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      -- optional (nicer ui)
      "stevearc/dressing.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    build = ":PympleBuild",
    opts = {
      keymaps = {
        -- Resolves import for symbol under cursor.
        -- This will automatically find and add the corresponding import to
        -- the top of the file (below any existing doctsring)
        resolve_import_under_cursor = {
          desc = "Resolve import under cursor",
          keys = "<leader>ci", -- feel free to change this to whatever you like
        },
      },
    },
  },
}
