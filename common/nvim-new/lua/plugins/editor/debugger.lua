local dap = {
  "mfussenegger/nvim-dap",
  enabled = false, -- debugging in VsCode seems noticeably better - I'll stick to that until there's a good reason to use nvim
  event = "VeryLazy",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "jay-babu/mason-nvim-dap.nvim",
    "theHamsta/nvim-dap-virtual-text",
  },
  keys = {
    {
      "<leader>d",
      group = "Debugger",
      nowait = true,
      remap = false,
    },
    {
      "<leader>dt",
      function()
        require("dap").toggle_breakpoint()
      end,
      desc = "Toggle Breakpoint",
      nowait = true,
      remap = false,
    },
    {
      "<leader>dc",
      function()
        require("dap").continue()
      end,
      desc = "Continue",
      nowait = true,
      remap = false,
    },
    {
      "<leader>di",
      function()
        require("dap").step_into()
      end,
      desc = "Step Into",
      nowait = true,
      remap = false,
    },
    {
      "<leader>do",
      function()
        require("dap").step_over()
      end,
      desc = "Step Over",
      nowait = true,
      remap = false,
    },
    {
      "<leader>du",
      function()
        require("dap").step_out()
      end,
      desc = "Step Out",
      nowait = true,
      remap = false,
    },
    {
      "<leader>dr",
      function()
        require("dap").repl.open()
      end,
      desc = "Open REPL",
      nowait = true,
      remap = false,
    },
    {
      "<leader>dl",
      function()
        require("dap").run_last()
      end,
      desc = "Run Last",
      nowait = true,
      remap = false,
    },
    {
      "<leader>dq",
      function()
        require("dap").terminate()
        require("dapui").close()
        require("nvim-dap-virtual-text").toggle()
      end,
      desc = "Terminate",
      nowait = true,
      remap = false,
    },
    {
      "<leader>db",
      function()
        require("dap").list_breakpoints()
      end,
      desc = "List Breakpoints",
      nowait = true,
      remap = false,
    },
    {
      "<leader>de",
      function()
        require("dap").set_exception_breakpoints({ "all" })
      end,
      desc = "Set Exception Breakpoints",
      nowait = true,
      remap = false,
    },
  },
  config = function()
    local dap = require("dap")
    dap.adapters.python = {
      type = "executable",
      command = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
      args = { "-m", "debugpy.adapter" },
    }
    dap.configurations.python = {
      {
        name = "debug sniff-py brain",
        type = "python",
        request = "launch",
        console = "integratedTerminal",
        cwd = vim.fn.getcwd(),
        program = "scripts.py",
        args = { "run", "scip" },
        pythonPath = function()
          -- Return a table: { python_executable, extra_args... }
          local cwd = vim.fn.getcwd()
          local python = vim.fn.executable(cwd .. "/.venv/bin/python") == 1 and (cwd .. "/.venv/bin/python")
            or vim.fn.exepath("python")
          return { python, "-Xfrozen_modules=off" }
        end,
        preLaunchTask = function()
          -- This will run 'poetry shell' before launching the debug session
          vim.fn.jobstart("poetry shell", { cwd = vim.fn.getcwd() })
        end,
      },
    }
  end,
}

vim.fn.sign_define("DapBreakpoint", { text = "🐞" })

return {
  dap,
}
