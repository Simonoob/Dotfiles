local pick = function()
  return require("telescope").extensions.refactoring.refactors()
  -- local refactoring = require "refactoring"
  -- refactoring.select_refactor()
end

return {
  {
    "ThePrimeagen/refactoring.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      { "<leader>cr", "", desc = "refactor", mode = { "n", "x" } },
      { "<leader>crf", "", desc = "function", mode = { "n", "x" } },
      { "<leader>crv", "", desc = "variable", mode = { "n", "x" } },
      { "<leader>crb", "", desc = "block", mode = { "n", "x" } },
      { "<leader>crd", "", desc = "debug", mode = { "n", "x" } },
    },
    opts = {
      prompt_func_return_type = {
        go = false,
        java = false,
        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
      },
      prompt_func_param_type = {
        go = false,
        java = false,
        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
      },
      printf_statements = {},
      print_var_statements = {},
      show_success_message = true, -- shows a message with information about the refactor on success
      -- i.e. [Refactor] Inlined 3 variable occurrences
    },
    config = function(_, opts)
      require("refactoring").setup(opts)

      -- [[KEYMAPS]]
      -- prompt for a refactor
      vim.keymap.set({ "n", "x" }, "<leader>crr", function()
        require("refactoring").select_refactor()
      end)

      -- [[functions]]
      vim.keymap.set({ "n", "x" }, "<leader>crfe", function()
        return require("refactoring").refactor("Extract Function")
      end, { expr = true, desc = "Extract function" })
      vim.keymap.set({ "n", "x" }, "<leader>crff", function()
        return require("refactoring").refactor("Extract Function To File")
      end, { expr = true, desc = "Extract function to File" })
      vim.keymap.set({ "n", "x" }, "<leader>crfi", function()
        return require("refactoring").refactor("Inline Function")
      end, { expr = true, desc = "Inline function" })

      -- [[variables]]
      vim.keymap.set({ "n", "x" }, "<leader>crve", function()
        return require("refactoring").refactor("Extract Variable")
      end, { expr = true, desc = "Extract variable" })
      vim.keymap.set({ "n", "x" }, "<leader>crvi", function()
        return require("refactoring").refactor("Inline Variable")
      end, { expr = true, desc = "Inline variable" })

      -- [[blocks]]
      vim.keymap.set({ "n", "x" }, "<leader>crbb", function()
        return require("refactoring").refactor("Extract Block")
      end, { expr = true, desc = "Extract block" })
      vim.keymap.set({ "n", "x" }, "<leader>crbf", function()
        return require("refactoring").refactor("Extract Block To File")
      end, { expr = true, desc = "Extract block to file" })

      -- [[DEBUG]]
      vim.keymap.set("n", "<leader>crde", function()
        require("refactoring").debug.printf({ below = false })
      end, {
        desc = "Print expression",
      })

      -- Print var

      vim.keymap.set(
        { "x", "n" },
        -- Supports both visual and normal mode
        "<leader>crdv",
        function()
          require("refactoring").debug.print_var()
        end,
        {
          desc = "Print var",
        }
      )

      vim.keymap.set("n", "<leader>crdc", function()
        require("refactoring").debug.cleanup({})
      end, {
        desc = "Cleanup",
      })

      require("telescope").load_extension("refactoring")

      -- NOT WORKING
      -- vim.keymap.set({ "n", "x" }, "<leader>crr", function()
      -- 	require("telescope").extensions.refactoring.refactors()
      -- end, {
      -- 	expr = true,
      -- 	desc = "Pick a refactor",
      -- })
    end,
  },
}
