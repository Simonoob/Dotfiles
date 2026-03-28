local colorscheme = {
  "catppuccin/nvim",
  pin = true,
  name = "catppuccin",
  priority = 1000,
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin-macchiato")
  end,
}

local highlight_comments = {
  -- Highlight todo, notes, etc in comments
  "folke/todo-comments.nvim",
  pin = true,
  event = "VimEnter",
  dependencies = { { "nvim-lua/plenary.nvim", pin = true } },
  opts = { signs = true },
}

local show_marks = {
  "chentoast/marks.nvim",
  pin = true,
  event = "VeryLazy",
  opts = {
    --  set_next               -- Set next available lowercase mark at cursor.
    -- toggle                 -- Toggle next available mark at cursor.
    -- delete_line            -- Deletes all marks on current line.
    -- delete_buf             -- Deletes all marks in current buffer.
    -- next                   -- Goes to next mark in buffer.
    -- prev                   -- Goes to previous mark in buffer.
    -- preview                -- Previews mark (will wait for user input). press <cr> to just preview the next mark.
    -- set                    -- Sets a letter mark (will wait for input).
    -- delete                 -- Delete a letter mark (will wait for input).
    default_mappings = false,
    sign_priority = 10, -- Higher priority than gitsigns (which uses default priority)
  },
  config = function(_, opts)
    require("marks").setup(opts)
    -- keymaps
    require("which-key").add({
      mode = { "n" },
      { "<leader>m", group = "marks", icon = { icon = "󰀫", color = "yellow" } },
      {
        "<leader>md",
        require("marks").delete_buf,
        desc = "Delete local marks",
      },
      {
        "m",
        function()
          -- Get the next character that will be input
          local char = vim.fn.getcharstr()
          if char == "" then
            return
          end -- User cancelled input

          local function set_mark(mark)
            -- Set the mark
            return vim.cmd("normal! m" .. mark)
          end

          -- Check if mark exists
          local mark_pos = vim.fn.getpos("'" .. char)
          if mark_pos[2] <= 0 then -- Mark doesn't exist
            return set_mark(char)
          end

          -- ask for confirmation
          vim.ui.select({ "overwrite", "view", "abort" }, {
            prompt = string.format("Mark '%s' already exists", char),
          }, function(choice)
            if choice == "overwrite" then
              return set_mark(char)
            elseif choice == "view" then
              vim.cmd(string.format("normal! '%s", char))
            end
          end)
        end,
        desc = "Set a mark",
      },
      {
        "<leader>mD",
        "<cmd>delmarks A-Za-b0-9<cr>",
        desc = "Delete all marks",
      },
      {
        "<leader>ml",
        require("marks").delete_line,
        desc = "Delete marks on line",
      },
      {
        "]m",
        require("marks").next,
        desc = "Next mark",
      },
      {
        "[m",
        require("marks").prev,
        desc = "Previous mark",
      },
    })
  end,
}

local snacks = {
  -- general UI QoL minor fixes
  "folke/snacks.nvim",
  pin = true,
  ---@module 'snacks'
  ---@type snacks.Config
  opts = {
    input = {
      enabled = false,
    },
    ---@class snacks.indent.Config
    indent = {
      ---@class snacks.indent.Scope.Config: snacks.scope.Config
      scope = {
        enabled = true, -- enable highlighting the current scope
        priority = 200,
        char = "│",
        underline = false, -- underline the start of the scope
        only_current = false, -- only show scope in the current window
        hl = "SnacksIndentScope", ---@type string|string[] hl group for scopes
      },
      chunk = {
        -- when enabled, scopes will be rendered as chunks, except for the
        -- top-level scope which will be rendered as a scope.
        enabled = false,
      },
      -- filter for buffers to enable indent guides
      filter = function(buf)
        return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype == ""
      end,
    },
  },
}

local highlight_matching_parenthesis = {
  "utilyre/sentiment.nvim",
  pin = true,
  version = "*",
  event = "VeryLazy", -- keep for lazy loading
  opts = {
    -- config
  },
  init = function()
    -- `matchparen.vim` needs to be disabled manually in case of lazy loading
    vim.g.loaded_matchparen = 1
  end,
}

local progress_and_notify_ui = {
  "j-hui/fidget.nvim",
  pin = true,
  opts = {
    -- options
  },
}

local scrolloff_eof = {
  -- keep the "scolloff" behaviour also at the end of the file
  "Aasim-A/scrollEOF.nvim",
  pin = true,
  event = { "CursorMoved", "WinScrolled" },
  opts = {},
}

-- DISABLED FOR NOW
-- local kitty_integration = {
--   "knubie/vim-kitty-navigator",
--   pin = true,
--   build = "cp ./*.py ~/.config/kitty/",
-- }

local better_messages_buffer = {
  -- overall better messages buffer (auto-update, normal buffer behaviour etc.)
  "ariel-frischer/bmessages.nvim",
  pin = true,
  event = "CmdlineEnter",
  opts = {},
}

return {
  colorscheme,
  highlight_comments,
  show_marks,
  snacks,
  highlight_matching_parenthesis,
  progress_and_notify_ui,
  scrolloff_eof,
  -- kitty_integration, -- disabled for now for conflicts with <C-k> etc. keymaps
  better_messages_buffer,
}
