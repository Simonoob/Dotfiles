return {
  -- actual symbols outline "map" for the current file
  -- TODO: make sure that it's still usable when having 2 separate files in 2 vertical splits
  "hedyhli/outline.nvim",
  pin = true,
  keys = { { "<leader>cs", "<cmd>Outline<cr>", desc = "Toggle Outline" } },
  cmd = "Outline",
  opts = function()
    local defaults = require("outline.config").defaults
    local opts = {
      symbols = {
        icons = {},
        filter = true,
      },
      keymaps = {
        up_and_jump = "<up>",
        down_and_jump = "<down>",
      },
    }

    for kind, symbol in pairs(defaults.symbols.icons) do
      opts.symbols.icons[kind] = {
        icon = symbol.icon,
        hl = symbol.hl,
      }
    end
    return opts
  end,
}
