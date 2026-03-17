local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local themes = require("telescope.themes")

-- ─── State ───────────────────────────────────────────────────────────────────

local M = {
  enabled = false,
  current_branch = nil,
  comparison_branch = nil,
  files = nil,
  hunks = nil,
  reviewed = {}, -- set of reviewed filenames
}

-- ─── Picker utilities ────────────────────────────────────────────────────────

--- Simple floating dropdown — no preview pane.
local function open_dropdown(opts)
  pickers.new(themes.get_dropdown(opts), {}):find()
end

--- Bottom-anchored ivy layout — supports a preview pane on the right.
local function open_with_preview(opts)
  pickers.new(themes.get_ivy(opts), {}):find()
end

-- ─── Git ─────────────────────────────────────────────────────────────────────

local function get_current_branch()
  return vim.fn.system("git branch --show-current | tr -d '\n'")
end

local function get_branches_list()
  local branches_raw = vim.fn.systemlist("git branch --format='%(refname:short)'")
  local seen = { main = true, master = true }
  local branches = { "main", "master" }

  for _, branch in ipairs(branches_raw) do
    if not seen[branch] then
      seen[branch] = true
      table.insert(branches, branch)
    end
  end

  return branches
end

local function get_modified_files(comparison_branch)
  local output = vim.fn.system("git diff --name-only --merge-base " .. comparison_branch)
  return vim.split(output, "\n")
end

local function get_modified_chunks(comparison_branch)
  local lines = vim.split(vim.fn.system("git diff " .. comparison_branch .. "..."), "\n")
  local chunks = {}
  local current_file = nil

  for _, line in ipairs(lines) do
    local file_match = line:match("^%+%+%+ b/(.+)$")
    if file_match then
      current_file = file_match
    end

    local chunk_match = line:match("^@@ %-[%d,]+ %+([%d,]+) @@")
    if chunk_match and current_file then
      table.insert(chunks, {
        filename = current_file,
        lnum = tonumber(vim.split(chunk_match, ",")[1]),
      })
    end
  end

  return chunks
end

-- ─── Gitsigns ────────────────────────────────────────────────────────────────

local function set_gitsigns_base()
  local common_commit = vim.system({ "git", "merge-base", M.comparison_branch, M.current_branch }):wait()
  vim.fn.execute(string.format("Gitsigns change_base %s global", common_commit.stdout))
end

local function add_hunks_to_quickfix()
  require("gitsigns").setqflist("all")
end

-- ─── Word wrap ───────────────────────────────────────────────────────────────

local function word_wrap(text, max_col)
  local result = {}
  for _, raw in ipairs(vim.split(text, "\n", { plain = true })) do
    if raw == "" then
      table.insert(result, "")
    else
      while #raw > max_col do
        local cut = raw:sub(1, max_col):match(".*()%s") or max_col
        table.insert(result, raw:sub(1, cut))
        raw = raw:sub(cut + 1):gsub("^%s+", "")
      end
      table.insert(result, raw)
    end
  end
  return result
end

-- ─── Status float ────────────────────────────────────────────────────────────

local function make_status_float(title, opts)
  opts = opts or {}
  local win_width = opts.width or 46
  local win_height = opts.height or 2
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = vim.o.lines - win_height - 3,
    col = math.floor((vim.o.columns - win_width) / 2),
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
    style = "minimal",
    focusable = false,
    noautocmd = true,
  })

  local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
  local spinner_idx = 1
  local _phase = ""
  local _content_lines = {}
  local max_col = win_width - 4 -- 2 indent + 2 margin

  local function render()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local display = { string.format("  %s %s…", spinner_frames[spinner_idx], _phase) }
    local max_lines = win_height - 1
    local start = math.max(1, #_content_lines - max_lines + 1)
    for i = start, #_content_lines do
      table.insert(display, "  " .. (_content_lines[i] or ""))
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, display)
  end

  local timer = vim.uv.new_timer()
  timer:start(
    0,
    80,
    vim.schedule_wrap(function()
      spinner_idx = (spinner_idx % #spinner_frames) + 1
      render()
    end)
  )

  return {
    phase = function(text)
      _phase = text or ""
    end,
    content = function(full_text)
      if not full_text or full_text == "" then
        _content_lines = {}
        return
      end
      local wrapped = word_wrap(full_text, max_col)
      while #wrapped > 0 and wrapped[#wrapped]:match("^%s*$") do
        table.remove(wrapped)
      end
      _content_lines = wrapped
    end,
    close = function()
      if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
      end
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end)
    end,
  }
end

-- ─── Branch picker ───────────────────────────────────────────────────────────

local function pick_branch(branches, on_select_fn)
  open_dropdown({
    prompt_title = "Select branch to compare against:",
    initial_mode = "normal",
    sorter = conf.generic_sorter({}),
    finder = finders.new_table({
      results = branches,
      entry_maker = function(entry)
        return { value = entry, display = entry, ordinal = entry }
      end,
    }),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selected = action_state.get_selected_entry()
        if not selected then
          vim.notify("No branch selected", vim.log.levels.WARN)
          return
        end
        on_select_fn(selected.value)
      end)
      map("n", "<Esc>", function()
        actions.close(prompt_bufnr)
      end)
      return true
    end,
  })
end

-- ─── File picker ─────────────────────────────────────────────────────────────

local function build_file_entries()
  -- Index chunks by file
  local chunks_by_file = {}
  for _, item in ipairs(M.hunks) do
    if not chunks_by_file[item.filename] then
      chunks_by_file[item.filename] = { count = 0, locations = {} }
    end
    chunks_by_file[item.filename].count = chunks_by_file[item.filename].count + 1
    table.insert(chunks_by_file[item.filename].locations, item)
  end

  -- Build entry list (skip empty strings from vim.split)
  local entries = {}
  for _, file in ipairs(M.files) do
    if file ~= "" then
      table.insert(entries, {
        filename = file,
        chunks = chunks_by_file[file] or { count = 0, locations = {} },
      })
    end
  end

  return entries
end

local function open_file_picker()
  if not M.enabled then
    vim.notify("Review mode is not ongoing. Start review mode first.", vim.log.levels.WARN)
    return
  end

  if not M.hunks or #M.hunks == 0 then
    vim.notify("No modified files found — start review mode first", vim.log.levels.WARN)
    return
  end

  local file_entries = build_file_entries()

  local displayer = entry_display.create({
    separator = " ",
    items = { { width = 2 }, { remaining = true }, { width = 10 } },
  })

  -- Rebuilt on every <Tab> toggle so ordinals and icons reflect current state.
  local function make_file_finder()
    return finders.new_table({
      results = file_entries,
      entry_maker = function(entry)
        local is_reviewed = M.reviewed[entry.filename]
        local parts = vim.split(entry.filename, "/")
        local short_name = #parts > 1 and ("…" .. parts[#parts - 1] .. "/" .. parts[#parts]) or entry.filename
        return {
          value = entry,
          filename = entry.filename,
          -- Reviewed files sort below pending ones.
          ordinal = string.format("%s_%s", is_reviewed and "z" or "a", entry.filename),
          display = function()
            local reviewed_now = M.reviewed[entry.filename]
            return displayer({
              { reviewed_now and "✓" or " ", reviewed_now and "DiagnosticOk" or "Comment" },
              short_name,
              { "[" .. entry.chunks.count .. " hunks]", "Comment" },
            })
          end,
        }
      end,
    })
  end

  open_with_preview({
    prompt_title = "Modified files — " .. M.comparison_branch,
    initial_mode = "normal",
    sorter = conf.generic_sorter({}),
    finder = make_file_finder(),
    attach_mappings = function(prompt_bufnr, map)
      -- Toggle reviewed and refresh the list in-place.
      map("n", "<Tab>", function()
        local selected = action_state.get_selected_entry()
        if not selected then
          return
        end
        local filename = selected.filename
        M.reviewed[filename] = not M.reviewed[filename] or nil
        action_state.get_current_picker(prompt_bufnr):refresh(make_file_finder(), { reset_prompt = false })
      end)

      -- Open the file and auto-mark it reviewed.
      actions.select_default:replace(function()
        local selected = action_state.get_selected_entry()
        if not selected then
          vim.notify("No file selected", vim.log.levels.WARN)
          return
        end
        actions.close(prompt_bufnr)
        M.reviewed[selected.filename] = true
        local chunks = selected.value.chunks
        if chunks.count > 0 then
          vim.cmd(string.format("edit +%d %s", chunks.locations[1].lnum, selected.value.filename))
        else
          vim.cmd(string.format("edit %s", selected.value.filename))
        end
      end)

      return true
    end,
  })
end

-- ─── Review lifecycle ────────────────────────────────────────────────────────

local function start_review_mode()
  if M.enabled then
    vim.notify("Review mode is already ongoing", vim.log.levels.WARN)
    return
  end

  pick_branch(get_branches_list(), function(selected_branch)
    M.comparison_branch = selected_branch
    M.current_branch = get_current_branch()
    M.enabled = true

    local status = make_status_float("Git Fetch")
    status.phase("Fetching")
    status.content(selected_branch)

    vim.system(
      { "git", "fetch", "origin", selected_branch .. ":" .. selected_branch },
      { text = true },
      vim.schedule_wrap(function(result)
        status.close()

        if result.code ~= 0 then
          vim.notify("git fetch failed: " .. (result.stderr or "unknown error"), vim.log.levels.ERROR)
          return
        end

        M.files = get_modified_files(selected_branch)
        M.hunks = get_modified_chunks(selected_branch)

        set_gitsigns_base()
        require("gitsigns").toggle_word_diff()

        open_file_picker()
      end)
    )
  end)
end

local function stop_review_mode(force)
  if not M.enabled and not force then
    vim.notify("Review mode is not ongoing", vim.log.levels.WARN)
    return
  end

  require("gitsigns").reset_base("global")
  require("gitsigns").toggle_word_diff()
  vim.cmd("Trouble qflist close")
  vim.fn.setqflist({}, "r")

  M.enabled = false
  M.comparison_branch = nil
  M.current_branch = nil
  M.reviewed = {}

  vim.notify("Review mode stopped", vim.log.levels.INFO)
end

-- ─── Public API ──────────────────────────────────────────────────────────────

-- Add to statusline: %{%v:lua.require'branch-review'.get_statusline_indicator()%}
function M.get_statusline_indicator()
  if not M.enabled then
    return ""
  end
  local total = M.files and #M.files or 0
  local done = 0
  for _ in pairs(M.reviewed) do
    done = done + 1
  end
  return string.format("[Review 󰘬 %s → %s  %d/%d]", M.current_branch, M.comparison_branch, done, total)
end

-- ─── Command & keymaps ───────────────────────────────────────────────────────

local valid_commands = { "start", "stop", "files", "hunksToQfixList" }

vim.api.nvim_create_user_command("BranchReview", function(opts)
  local cmd = opts.args
  if not vim.tbl_contains(valid_commands, cmd) then
    vim.notify("Invalid command. Valid: " .. vim.inspect(valid_commands), vim.log.levels.ERROR)
    return
  end

  if cmd == "start" then
    start_review_mode()
  elseif cmd == "stop" then
    stop_review_mode()
  elseif cmd == "files" then
    open_file_picker()
  elseif cmd == "hunksToQfixList" then
    add_hunks_to_quickfix()
  end
end, {
  nargs = 1,
  desc = "Git branch review mode",
  complete = function(ArgLead, CmdLine)
    for _, cmd in ipairs(valid_commands) do
      if CmdLine:match(cmd) then
        return {}
      end
    end
    local matches = {}
    for _, cmd in ipairs(valid_commands) do
      if cmd:match("^" .. ArgLead) then
        table.insert(matches, cmd)
      end
    end
    return matches
  end,
})

M.setup = function()
  vim.keymap.set("n", "<leader>gr", "", { desc = "Git branch review" })
  vim.keymap.set("n", "<leader>grt", function()
    vim.cmd(M.enabled and "BranchReview stop" or "BranchReview start")
  end, { desc = "toggle review mode" })
  vim.keymap.set("n", "<leader>grq", "<cmd>BranchReview hunksToQfixList<cr>", { desc = "add hunks to quickfix" })
  vim.keymap.set("n", "<leader>grf", "<cmd>BranchReview files<cr>", { desc = "open modified files" })
end

return M
