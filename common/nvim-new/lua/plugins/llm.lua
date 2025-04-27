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

            Remember, you are a coding assistant useful mostly to explore and understand code in the current project.
            Be concise and avoid unnecessary details. Your efforts are best spent in exploring the code and providing useful information on its structure and usage.
            If you are not certain about something, say so explicitly and ask for more context if needed.
            Be always concise, never verbose, do not pollute the output.

            for lua code, use lua 5.1
            for neovim api, use nvim 0.11

            if you need more context, return a cli command to get the context from files in the current project.
            use ripgrep heavily to search for the context, with the rg command.
            format command requests as following:
            # command request start
            <command> <args>
            # command request end


            to get the file structure from a specific directory, use the command:
            find <target-directory> | sed -e "s/[^-][^\/]*\// |/g" -e "s/|\([^ ]\)/|-\1/"

            to get the current working directory, use the command:
            pwd 

            to get the root of the current git project, use the command:
            git rev-parse --show-toplevel 


            e.g. look for mentions of the function `foo` in the current git project:
            # command request start
            rg -n 'foo' $(git rev-parse --show-toplevel) 
            # command request end


            e.g. check the file and folder structure of the current git project (respecting .gitignore):
            # command request start 
            git ls-files --others --cached --exclude-standard | sed -e "s|$(git rev-parse --show-toplevel)/||" | sort | sed -e "s/[^-][^\/]*\// |/g" -e "s/|\([^ ]\)/|-\1/"
            # command request end
          ]],
        },
      },
    }

    require("gp").setup(conf)

    -- Setup shortcuts here (see Usage > Shortcuts in the Documentation/Readme)
    require("which-key").add({
      -- VISUAL mode mappings
      -- s, x, v modes are handled the same way by which_key
      {
        mode = { "v" },
        nowait = true,
        remap = false,
        { "<C-g><C-t>", ":<C-u>'<,'>GpChatNew tabnew<cr>", desc = "ChatNew tabnew" },
        { "<C-g><C-v>", ":<C-u>'<,'>GpChatNew vsplit<cr>", desc = "ChatNew vsplit" },
        { "<C-g><C-x>", ":<C-u>'<,'>GpChatNew split<cr>", desc = "ChatNew split" },
        { "<C-g>a", ":<C-u>'<,'>GpAppend<cr>", desc = "Visual Append (after)" },
        { "<C-g>b", ":<C-u>'<,'>GpPrepend<cr>", desc = "Visual Prepend (before)" },
        { "<C-g>c", ":<C-u>'<,'>GpChatNew<cr>", desc = "Visual Chat New" },
        { "<C-g>g", group = "generate into new .." },
        { "<C-g>ge", ":<C-u>'<,'>GpEnew<cr>", desc = "Visual GpEnew" },
        { "<C-g>gn", ":<C-u>'<,'>GpNew<cr>", desc = "Visual GpNew" },
        { "<C-g>gp", ":<C-u>'<,'>GpPopup<cr>", desc = "Visual Popup" },
        { "<C-g>gt", ":<C-u>'<,'>GpTabnew<cr>", desc = "Visual GpTabnew" },
        { "<C-g>gv", ":<C-u>'<,'>GpVnew<cr>", desc = "Visual GpVnew" },
        { "<C-g>i", ":<C-u>'<,'>GpImplement<cr>", desc = "Implement selection" },
        { "<C-g>n", "<cmd>GpNextAgent<cr>", desc = "Next Agent" },
        { "<C-g>p", ":<C-u>'<,'>GpChatPaste<cr>", desc = "Visual Chat Paste" },
        { "<C-g>r", ":<C-u>'<,'>GpRewrite<cr>", desc = "Visual Rewrite" },
        { "<C-g>s", "<cmd>GpStop<cr>", desc = "GpStop" },
        { "<C-g>t", ":<C-u>'<,'>GpChatToggle<cr>", desc = "Visual Toggle Chat" },
        { "<C-g>x", ":<C-u>'<,'>GpContext<cr>", desc = "Visual GpContext" },
      },

      -- NORMAL mode mappings
      {
        mode = { "n" },
        nowait = true,
        remap = false,
        { "<C-g><C-t>", "<cmd>GpChatNew tabnew<cr>", desc = "New Chat tabnew" },
        { "<C-g><C-v>", "<cmd>GpChatNew vsplit<cr>", desc = "New Chat vsplit" },
        { "<C-g><C-x>", "<cmd>GpChatNew split<cr>", desc = "New Chat split" },
        { "<C-g>a", "<cmd>GpAppend<cr>", desc = "Append (after)" },
        { "<C-g>b", "<cmd>GpPrepend<cr>", desc = "Prepend (before)" },
        { "<C-g>c", "<cmd>GpChatNew<cr>", desc = "New Chat" },
        { "<C-g>f", "<cmd>GpChatFinder<cr>", desc = "Chat Finder" },
        { "<C-g>g", group = "generate into new .." },
        { "<C-g>ge", "<cmd>GpEnew<cr>", desc = "GpEnew" },
        { "<C-g>gn", "<cmd>GpNew<cr>", desc = "GpNew" },
        { "<C-g>gp", "<cmd>GpPopup<cr>", desc = "Popup" },
        { "<C-g>gt", "<cmd>GpTabnew<cr>", desc = "GpTabnew" },
        { "<C-g>gv", "<cmd>GpVnew<cr>", desc = "GpVnew" },
        { "<C-g>n", "<cmd>GpNextAgent<cr>", desc = "Next Agent" },
        { "<C-g>r", "<cmd>GpRewrite<cr>", desc = "Inline Rewrite" },
        { "<C-g>s", "<cmd>GpStop<cr>", desc = "GpStop" },
        { "<C-g>t", "<cmd>GpChatToggle<cr>", desc = "Toggle Chat" },
        { "<C-g>x", "<cmd>GpContext<cr>", desc = "Toggle GpContext" },
      },

      -- INSERT mode mappings
      {
        mode = { "i" },
        nowait = true,
        remap = false,
        { "<C-g><C-t>", "<cmd>GpChatNew tabnew<cr>", desc = "New Chat tabnew" },
        { "<C-g><C-v>", "<cmd>GpChatNew vsplit<cr>", desc = "New Chat vsplit" },
        { "<C-g><C-x>", "<cmd>GpChatNew split<cr>", desc = "New Chat split" },
        { "<C-g>a", "<cmd>GpAppend<cr>", desc = "Append (after)" },
        { "<C-g>b", "<cmd>GpPrepend<cr>", desc = "Prepend (before)" },
        { "<C-g>c", "<cmd>GpChatNew<cr>", desc = "New Chat" },
        { "<C-g>f", "<cmd>GpChatFinder<cr>", desc = "Chat Finder" },
        { "<C-g>g", group = "generate into new .." },
        { "<C-g>ge", "<cmd>GpEnew<cr>", desc = "GpEnew" },
        { "<C-g>gn", "<cmd>GpNew<cr>", desc = "GpNew" },
        { "<C-g>gp", "<cmd>GpPopup<cr>", desc = "Popup" },
        { "<C-g>gt", "<cmd>GpTabnew<cr>", desc = "GpTabnew" },
        { "<C-g>gv", "<cmd>GpVnew<cr>", desc = "GpVnew" },
        { "<C-g>n", "<cmd>GpNextAgent<cr>", desc = "Next Agent" },
        { "<C-g>r", "<cmd>GpRewrite<cr>", desc = "Inline Rewrite" },
        { "<C-g>s", "<cmd>GpStop<cr>", desc = "GpStop" },
        { "<C-g>t", "<cmd>GpChatToggle<cr>", desc = "Toggle Chat" },
        { "<C-g>x", "<cmd>GpContext<cr>", desc = "Toggle GpContext" },
      },
    })
  end,
}

return {
  copilot_base,
  copilot_cmp,
  ai_agent,
}
