local copilot_base = {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      suggestion = { enabled = false },
      panel = { enabled = false },
    })
  end,
}

local copilot_cmp = {
  "zbirenbaum/copilot-cmp",
  dependencies = { "zbirenbaum/copilot.lua" },
  config = function()
    require("copilot_cmp").setup()
  end,
}

local ai_agent = {
  "robitx/gp.nvim",
  config = function()
    local conf = {
      -- For customization, refer to Install > Configuration in the Documentation/Readme
      providers = {
        openai = {},
        copilot = {
          disabled = false,
          endpoint = "https://api.githubcopilot.com/chat/completions",
          secret = {
            "bash",
            "-c",
            "cat ~/.config/github-copilot/apps.json | sed -e 's/.*oauth_token...//;s/\".*//'",
          },
        },
      },
      agents = {
        {
          name = "MyCustomAgent",
          provider = "copilot",
          chat = true,
          command = true,
          model = { model = "gpt-4o" },
          system_prompt = [[
            for lua code, use lua 5.1
            for neovim api, use nvim 0.11

            if you need more context, return a cli command to get the context from files in the current project.
            use ripgrep heavily to search for the context, with the rg command.
            format command requests as following:
            # command request start
            <command> <args>
            # command request end
          ]],
        },
      },
    }

    require("gp").setup(conf)

    -- Setup shortcuts here (see Usage > Shortcuts in the Documentation/Readme)
  end,
}

return {
  copilot_base,
  copilot_cmp,
  ai_agent,
}
