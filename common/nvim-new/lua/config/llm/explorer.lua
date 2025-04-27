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

local function run_cmd_and_append_output(cmd, chat_buffer)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()

  -- Use folding markers for the code block to make it foldable
  local folding_start = "{{{"
  local folding_end = "}}}"

  local formatted_result = string.format("```\n%s\n%s\n%s\n%s\n```", cmd, folding_start, result, folding_end)

  -- Split the folding content into lines
  local formatted_lines = vim.split(formatted_result, "\n")
  for _, line in ipairs(formatted_lines) do
    vim.api.nvim_buf_set_lines(chat_buffer, -1, -1, false, { line })
  end

  -- Configure foldmethod for the buffer
  vim.api.nvim_buf_set_option(chat_buffer, "foldmethod", "marker")
  vim.api.nvim_buf_set_option(chat_buffer, "foldlevel", 0) -- Close all folds by default

  vim.cmd("GpChatRespond")
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

    for _, cmd in ipairs(commands) do
      -- if command is a read-only command (like find, rg, cat), run it without confirmation
      if cmd:match("^find") or cmd:match("^rg") or cmd:match("^cat") then
        print("read-only command found: " .. cmd)
        run_cmd_and_append_output(cmd, chat_buffer)
      else
        -- select if you want to execute the command
        vim.ui.select({ "Modify and execute", "Reject" }, { prompt = "Choose action for: " .. cmd }, function(choice)
          if choice == "Modify and execute" then
            -- modify and run command
            vim.ui.input({ prompt = "Modify command: ", default = cmd }, function(modified_cmd)
              if not modified_cmd then
                return -- User cancelled
              end

              run_cmd_and_append_output(modified_cmd, chat_buffer)
            end)
          end
        end)
      end
    end
  end,
})

-- Keymaps for easy access
function M.setup()
  vim.keymap.set("n", "<leader>rr", function()
    local handle = io.popen([[
rg -g '**/explorer.lua' --files $(git rev-parse --show-toplevel) 
]])
    local result = handle:read("*a")
    handle:close()
    print("Command executed: " .. vim.inspect(result))
  end, { desc = "Start refactoring chat" })
end

return M
