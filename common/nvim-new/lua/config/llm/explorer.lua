local M = {}

local gp = require("gp")
local Path = require("plenary.path")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Step 1: Open floating chat **with** a callback
-- function M.start_refactor_chat()
--   local params = {
--     args = "popup", -- open in floating chat
--     range = 0, -- zero-line “selection”
--     line1 = 1, -- start at line 1
--     line2 = 0, -- end _before_ line 1, i.e. empty
--   } -- no range, args, etc
--   local target = gp.Target.popup -- floating popup
--   local agent = gp.get_chat_agent("MyCustomAgent")
--   local template = [[
-- You are an expert code–refactoring assistant.
-- When you need extra project context, emit **only** lines like:
--
--   get context: <shell command>
--
-- and then wait for me to fetch that before you continue.
-- ]]
--
--   local prompt_str = "write comments for refactor.lua" -- no interactive user prompt
--   local whisper = nil -- not using Whisper here
--
--   -- **This** callback will fire exactly **once**, after the full GPT stream completes:
--   local callback = function(full_response)
--     M.handle_response(full_response)
--   end
--
--   gp.Prompt(params, target, agent, template, prompt_str, whisper, callback)
-- end

-- function M.handle_response(response)
--   print("Handling response...")
--   for cmd in response:gmatch("get context:%s*(.-)\n") do
--     M.confirm_and_run(vim.trim(cmd))
--   end
-- end

-- Step 3: Ask user, run the shell command asynchronously, and append its output
-- function M.confirm_and_run(cmd)
--   vim.ui.select({ "Yes", "No" }, {
--     prompt = "Run command: " .. cmd .. "?",
--   }, function(choice)
--     if choice == "Yes" then
--       vim.fn.jobstart(vim.split(cmd, " "), {
--         stdout_buffered = true,
--         on_stdout = function(_, data)
--           if data and #data > 0 then
--             local result = table.concat(data, "\n")
--             print("result")
--           end
--         end,
--         on_stderr = function(_, err)
--           if err and #err > 0 then
--             vim.notify("Error running `" .. cmd .. "`: " .. table.concat(err, "\n"), vim.log.levels.ERROR)
--           end
--         end,
--       })
--     end
--   end)
-- end

vim.api.nvim_create_autocmd({ "User" }, {
  pattern = { "GpDone" },
  callback = function(event)
    print("event fired:\n", vim.inspect(event))
    local b = event.buf
    print(event.buf)
    -- DO something
  end,
})

-- Keymaps for easy access
function M.setup()
  -- vim.keymap.set("n", "<leader>rr", M.start_refactor_chat, { desc = "Start refactoring chat" })
end

return M
