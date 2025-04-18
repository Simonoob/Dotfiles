local auto_pairs = {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    require("nvim-autopairs").setup({
      disable_filetype = { "TelescopePrompt", "vim" },
      ignored_next_char = "[%w%.]", -- will ignore alphanumeric and `.` symbol
    })
    -- automatically add `(` after selecting a function or method
    local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    local cmp = require("cmp")
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end,
}
local auto_pair_html_tags = {
  "windwp/nvim-ts-autotag",
  config = function()
    require("nvim-ts-autotag").setup({
      opts = {
        -- Defaults
        enable_close = true, -- Auto close tags
        enable_rename = true, -- Auto rename pairs of tags
        enable_close_on_slash = false, -- Auto close on trailing </
      },
      -- Also override individual filetype configs, these take priority.
      -- Empty by default, useful if one of the "opts" global settings
      -- doesn't work well in a specific filetype
      -- per_filetype = {
      -- 	["html"] = {
      -- 		enable_close = false,
      -- 	},
      -- },
    })
  end,
}

local auto_detect_tabs = {
  "tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically
}

local inc_rename = {
  "smjonas/inc-rename.nvim",
  config = function()
    require("inc_rename").setup()
  end,
  keys = {
    {
      mode = { "n" },
      "<leader>cR",
      function()
        return ":IncRename " .. vim.fn.expand("<cword>")
      end,
      expr = true,
      desc = "Rename (inc-rename.nvim)",
    },
  },
}

return {
  auto_detect_tabs,
  auto_pairs,
  auto_pair_html_tags,
  inc_rename,
}
