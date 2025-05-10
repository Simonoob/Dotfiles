local colorscheme = {
  "ellisonleao/gruvbox.nvim",
  lazy = false, -- make sure we load this during startup if it is your main colorscheme
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    require("gruvbox").setup({
      terminal_colors = true, -- add neovim terminal colors
      undercurl = true,
      underline = true,
      bold = true,
      italic = {
        strings = true,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
      },
      strikethrough = true, -- Enable strikethrough text

      -- Background options
      invert_selection = false, -- Don't invert selected text
      invert_signs = false, -- Don't invert gutter signs
      invert_tabline = false, -- Don't invert tabline
      invert_intend_guides = false, -- Don't invert indent guides
      inverse = true, -- Invert background for search, diffs, statuslines and errors

      -- Can be "hard" (more contrast), "soft" (less contrast) or "" (default)
      contrast = "",

      -- Override specific color groups to use other groups or a hex color
      palette_overrides = {}, -- Override specific colors in the palette
      overrides = {}, -- Override highlight groups

      -- Window options
      dim_inactive = false, -- Don't dim inactive windows
      transparent_mode = false, -- No transparency (set true if you use terminal transparency)
    })

    -- Set colorscheme after options
    -- Toggle between modes with ':set background=dark/light'
    vim.cmd("colorscheme gruvbox")

    -- set sign column color (left gutter) to the `GruvboxBg0` highlight group
    vim.cmd("highlight SignColumn guibg=GruvboxBg0")
  end,
}

local highlight_comments = {
  -- Highlight todo, notes, etc in comments
  "folke/todo-comments.nvim",
  event = "VimEnter",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = { signs = false },
}

local show_marks = {
  "chentoast/marks.nvim",
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
          vim.ui.select({ "abort", "overwrite", "view" }, {
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
  "folke/snacks.nvim",
  ---@type snacks.Config
  priority = 1000,
  opts = {
    input = {
      enabled = true,
    },
    ---@field enabled? boolean
    ---@class snacks.indent.Config
    indent = {
      indent = {
        enabled = false,
      },
      -- animate scopes. Enabled by default for Neovim >= 0.10
      -- Works on older versions but has to trigger redraws during animation.
      ---@class snacks.indent.animate: snacks.animate.Config
      ---@field enabled? boolean
      --- * out: animate outwards from the cursor
      --- * up: animate upwards from the cursor
      --- * down: animate downwards from the cursor
      --- * up_down: animate up or down based on the cursor position
      ---@field style? "out"|"up_down"|"down"|"up"
      animate = {
        enabled = false,
      },
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
  opts = {
    -- options
  },
}

local scrolloff_eof = {
  -- keep the "scolloff" behaviour also at the end of the file
  "Aasim-A/scrollEOF.nvim",
  event = { "CursorMoved", "WinScrolled" },
  opts = {},
}

local zen_ui = {
  "folke/zen-mode.nvim",
  dependencies = {
    {
      "folke/twilight.nvim",
      opts = {
        dimming = {
          alpha = 0.25, -- amount of dimming
          -- we try to get the foreground from the highlight groups or fallback color
          color = { "Normal", "#ffffff" },
          term_bg = "#000000", -- if guibg=NONE, this will be used to calculate text color
          inactive = true, -- when true, other windows will be fully dimmed (unless they contain the same buffer)
        },
        context = 50, -- amount of lines we will try to show around the current line
        treesitter = true, -- use treesitter when available for the filetype
        -- treesitter is used to automatically expand the visible text,
        -- but you can further control the types of nodes that should always be fully expanded
        expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
          "function",
          "method",
          "table",
          "if_statement",
        },
        exclude = {}, -- exclude these filetypes
      },
    },
  },
  opts = {
    window = {
      backdrop = 0.95, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
      -- height and width can be:
      -- * an absolute number of cells when > 1
      -- * a percentage of the width / height of the editor when <= 1
      -- * a function that returns the width or the height
      width = 120, -- width of the Zen window
      height = 1, -- height of the Zen window
      -- by default, no options are changed for the Zen window
      -- uncomment any of the options below, or add other vim.wo options you want to apply
      options = {
        -- signcolumn = "no", -- disable signcolumn
        -- number = false, -- disable number column
        -- relativenumber = false, -- disable relative numbers
        -- cursorline = false, -- disable cursorline
        -- cursorcolumn = false, -- disable cursor column
        -- foldcolumn = "0", -- disable fold column
        -- list = false, -- disable whitespace characters
      },
    },
    plugins = {
      -- disable some global vim options (vim.o...)
      -- comment the lines to not apply the options
      options = {
        enabled = true,
        ruler = false, -- disables the ruler text in the cmd line area
        showcmd = false, -- disables the command in the last line of the screen
        -- you may turn on/off statusline in zen mode by setting 'laststatus'
        -- statusline will be shown only if 'laststatus' == 3
        laststatus = 3, -- turn off the statusline in zen mode
      },
      twilight = { enabled = false }, -- enable to start Twilight when zen mode opens
      gitsigns = { enabled = false }, -- disables git signs
      tmux = { enabled = false }, -- disables the tmux statusline
      todo = { enabled = false }, -- if set to "true", todo-comments.nvim highlights will be disabled
      -- this will change the font size on kitty when in zen mode
      -- to make this work, you need to set the following kitty options:
      -- - allow_remote_control socket-only
      -- - listen_on unix:/tmp/kitty
      kitty = {
        enabled = false,
        font = "+1", -- font size increment
      },
    },
    -- callback where you can add custom code when the Zen window opens
    on_open = function(win) end,
    -- callback where you can add custom code when the Zen window closes
    on_close = function() end,
  },

  config = function(_, opts)
    require("zen-mode").setup(opts)
    vim.keymap.set({ "n" }, "<leader>tz", function()
      require("zen-mode").toggle({
        window = {
          width = math.min(150, math.floor(vim.o.columns * 0.9)),
        },
      })
    end, { desc = "Toggle zen mode" })
  end,
}

local kitty_integration = {
  "knubie/vim-kitty-navigator",
  build = "cp ./*.py ~/.config/kitty/",
}

return {
  colorscheme,
  highlight_comments,
  show_marks,
  snacks,
  highlight_matching_parenthesis,
  progress_and_notify_ui,
  scrolloff_eof,
  zen_ui,
  kitty_integration,
}
