return {
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
  },
  config = function(_, opts)
    require("marks").setup(opts)
    -- keymaps
    require("which-key").add {
      mode = { "n" },
      { "<leader>m", group = "marks", icon = { icon = "󰀫", color = "yellow" } },
      {
        "<leader>ma",
        require("marks").set,
        desc = "New mark",
      },
      {
        "<leader>md",
        require("marks").delete,
        desc = "Delete mark",
      },
      {
        "<leader>mD",
        require("marks").delete_buf,
        desc = "Delete all marks in buffer",
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
    }
  end,
}
