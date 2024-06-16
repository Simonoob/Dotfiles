lvim.plugins = {
  -- {
  --   'zbirenbaum/copilot.lua',
  --   cmd = "Copilot",
  --   event = "InsertEnter",
  --   config = function()
  --     require("user/plugins/custom/copilot")
  --   end,
  -- },
  {
    'windwp/nvim-ts-autotag',
    init = function()
      require('nvim-ts-autotag').setup()
    end,
  },
  {
    'mrjones2014/nvim-ts-rainbow',
    init = function()
      require('nvim-treesitter.configs').setup({
        highlight = {
          -- ...
        },
        -- ...
        rainbow = {
          enable = true,
          -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
          extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
          max_file_lines = nil, -- Do not enable for files with more than n lines, int
          -- colors = {}, -- table of hex strings
          -- termcolors = {} -- table of colour name strings
        },
      })
    end,
  },
  -- {
  --   'folke/twilight.nvim',
  --   init = function()
  --     require("twilight").setup()
  --     vim.cmd("TwilightEnable") -- enable it by default
  --   end,
  -- }
  -- {
  --   "m4xshen/hardtime.nvim",
  --   init = function()
  --     require("hardtime").setup()
  --   end,
  -- },
  { "jwalton512/vim-blade" },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "nvim-telescope/telescope-live-grep-args.nvim",
        -- This will not install any breaking changes.
        -- For major updates, this must be adjusted manually.
        version = "^1.0.0",
      },
    },
    init = function()
      require("telescope").load_extension("live_grep_args")
    end
  },
  {
    'joechrisellis/lsp-format-modifications.nvim',
  },
}
