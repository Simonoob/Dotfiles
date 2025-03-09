-- which-key helps you remember key bindings by showing a popup
-- with the active keybindings of the command you started typing.
return {
  "folke/which-key.nvim",
  lazy = false,
  opts_extend = { "spec" },
  opts = {
    preset = "modern",
    defaults = {},
    spec = {
      {
        mode = { "n", "v" },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "ebug" },
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "git" },
        { "<leader>gh", group = "hunks" },
        { "<leader>q", group = "quit/session" },
        { "<leader>s", group = "search" },
        { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
        { "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
        { "<leader>z", group = "folds", icon = { icon = "", color = "green" } },
        { "[", group = "prev" },
        { "]", group = "next" },
        { "g", group = "goto" },
        {
          "<leader>b",
          group = "buffer",
          expand = function()
            return require("which-key.extras").expand.buf()
          end,
        },
        -- better descriptions
        { "gx", desc = "Open with system app" },
      },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show { global = false }
      end,
      desc = "Buffer Keymaps (which-key)",
    },
    {
      "<c-w><space>",
      function()
        require("which-key").show { keys = "<c-w>", loop = true }
      end,
      desc = "Window Hydra Mode (which-key)",
    },
  },
}
