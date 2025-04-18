local mini_nvim = { -- Collection of various small independent plugins/modules
  "echasnovski/mini.nvim",
  version = false,
  config = function()
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    require("mini.ai").setup({ n_lines = 500 })

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require("mini.surround").setup()

    -- quality of life plugin for comments - works in tandem with smart_comments below
    require("mini.comment").setup()
  end,
}

local smart_comments = {
  -- smart augmentation of comments based on treesitter nodes
  -- it helps to e.g. format comments correctly in .tsx files based on cursor location (TS context | JSX context)
  "folke/ts-comments.nvim",
  opts = {},
  event = "VeryLazy",
  enabled = vim.fn.has("nvim-0.10.0") == 1,
}

return { smart_comments, mini_nvim }
