local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local M = {}

local find_marks = function(opts)
  opts = opts or {}

  -- Get both global and local marks
  local global_marks = vim.fn.getmarklist()
  local buffer_marks = vim.fn.getmarklist(vim.fn.bufnr())
  local results = {}

  local function process_mark(mark)
    if mark.pos[2] < 0 then -- Only include valid marks
      return
    end

    local mark_symbol = mark.mark:sub(2) -- Remove the ' prefix

    if string.match(mark_symbol, "%w") == nil then -- Skip marks that are not defined by the user
      return
    end

    local bufname = vim.fn.bufname(mark.pos[1])
    if bufname ~= "" then
      table.insert(results, {
        mark = mark_symbol,
        filename = vim.fn.fnamemodify(bufname, ":p"),
        lnum = mark.pos[2],
        col = mark.pos[3] - 1,
        text = vim.api.nvim_buf_get_lines(mark.pos[1], mark.pos[2] - 1, mark.pos[2], false)[1] or "",
      })
    end
  end

  -- Process global marks
  for _, mark in ipairs(global_marks) do
    process_mark(mark)
  end
  -- Process buffer marks
  for _, mark in ipairs(buffer_marks) do
    process_mark(mark)
  end

  -- Create the finder with proper display
  local finder = finders.new_table({
    results = results,
    entry_maker = function(entry)
      return {
        value = entry,
        display = entry.mark .. " | " .. vim.fn.fnamemodify(entry.filename, ":~:.") .. ":" .. entry.lnum,
        ordinal = entry.mark .. " " .. entry.filename .. " " .. entry.text,
        mark = entry.mark,
        filename = entry.filename,
        lnum = entry.lnum,
        col = entry.col,
        text = entry.text,
      }
    end,
  })

  -- Create the picker
  pickers
    .new(opts, {
      prompt_title = "Find Marks",
      finder = finder,
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          -- Navigate to the correct buffer first if needed
          if selection.filename ~= vim.fn.expand("%:p") then
            vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
          end

          -- Jump to the mark position
          vim.api.nvim_win_set_cursor(0, { selection.lnum, selection.col })
        end)
        return true
      end,
    })
    :find()
end

M.setup = function()
  vim.keymap.set("n", "<leader>fm", find_marks, { desc = "find marks" })
end

return M
