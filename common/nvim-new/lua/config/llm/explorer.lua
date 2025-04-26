local M = {}

local gp = require("gp")
local Path = require("plenary.path")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- get the latest response from the chat buffer
-- responses start with a line starting with "🤖:[", and continue multiline
local function get_latest_response(chat_buf)
  -- Ensure the buffer is valid
  if not vim.api.nvim_buf_is_valid(chat_buf) then
    return ""
  end

  -- Retrieve lines from the chat buffer
  local lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)

  -- Scan backwards to locate the beginning of the most recent response
  local response_start = nil
  for i = #lines, 1, -1 do
    if lines[i]:match("^🤖:%[") then
      response_start = i
      break
    end
  end

  -- If no response start was found, return empty string
  if not response_start then
    return ""
  end

  -- Collect the lines of the response
  local response_lines = {}
  for i = response_start, #lines do
    table.insert(response_lines, lines[i])
  end

  return response_lines
end

local function extract_shell_commands(lines)
  local commands = {}
  local is_command_request = false
  for _, line in ipairs(lines) do
    if line:match("^# command request start") then
      is_command_request = true
    elseif line:match("^# command request end") then
      is_command_request = false
    elseif is_command_request then
      table.insert(commands, line)
    end
  end
  return commands
end

vim.api.nvim_create_autocmd({ "User" }, {
  pattern = { "GpDone" },
  callback = function(event)
    -- check if we are in a buffer that is a chat buffer
    if not (vim.bo.filetype == "markdown" and vim.fn.expand("%:p"):match("/gp/chats/")) then
      return
    end

    local chat_buffer = event.buf

    local commands = extract_shell_commands(get_latest_response(chat_buffer))

    if #commands == 0 then
      print("No commands found in chat buffer.")
      return
    end

    -- for each command, prompt the user to modify and execute it or to reject it
    -- use vim.ui.select for prompt the user, the options are:
    -- 1. Modify and execute
    -- 2. Reject
    -- on select, open a prompt to modify the command
    -- if reject, do nothing and continue to the next command
    -- if modify and execute, run the command and print the result in the chat buffer
    -- format the result as the fllowing:
    -- ```
    -- <command>
    -- <result>
    -- ```

    for _, cmd in ipairs(commands) do
      vim.ui.select({ "Modify and execute", "Reject" }, { prompt = "Choose action for: " .. cmd }, function(choice)
        if choice == "Modify and execute" then
          vim.ui.input({ prompt = "Modify command: ", default = cmd }, function(modified_cmd)
            if modified_cmd then
              -- execute the shell command in a separate process, capture the output and append it to the chat buffer.
              -- make sure to not block the UI and update the buffer in a non-blocking way - write an update to the buffer while the command is running
              local formatted_result = "```\n" .. modified_cmd .. "\n" .. result .. "```"
              vim.api.nvim_buf_set_lines(chat_buffer, -1, -1, false, { formatted_result })
            end
          end)
        end
      end)
    end
  end,
})

-- Keymaps for easy access
function M.setup()
  -- vim.keymap.set("n", "<leader>rr", M.start_refactor_chat, { desc = "Start refactoring chat" })
end

return M
