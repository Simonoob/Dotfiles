return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require("gruvbox").setup {
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
      }

      -- Set colorscheme after options
      -- Toggle between modes with ':set background=dark/light'
      vim.cmd "colorscheme gruvbox"
    end,
  },
}
