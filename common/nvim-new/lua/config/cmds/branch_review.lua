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
  ai_summary = nil, -- string: overall PR summary
  ai_suggestions = nil, -- map: filename -> { order, change_type, description }
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

  -- Sort by AI-suggested priority when available
  if M.ai_suggestions then
    table.sort(entries, function(a, b)
      local oa = (M.ai_suggestions[a.filename] or {}).order or 999
      local ob = (M.ai_suggestions[b.filename] or {}).order or 999
      return oa < ob
    end)
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

  local type_hl = {
    feature = "Function",
    fix = "DiagnosticError",
    refactor = "Type",
    test = "DiagnosticHint",
    chore = "Comment",
    docs = "String",
  }

  local displayer = entry_display.create({
    separator = " ",
    items = { { width = 2 }, { remaining = true }, { width = 10 } },
  })

  -- Rebuilt on every <Tab> toggle so ordinals and icons reflect current state.
  local function make_file_finder()
    return finders.new_table({
      results = file_entries,
      entry_maker = function(entry)
        local ai = M.ai_suggestions and M.ai_suggestions[entry.filename]
        local is_reviewed = M.reviewed[entry.filename]
        local parts = vim.split(entry.filename, "/")
        local short_name = #parts > 1 and ("…" .. parts[#parts - 1] .. "/" .. parts[#parts]) or entry.filename
        return {
          value = entry,
          filename = entry.filename,
          -- Reviewed files sort below pending ones; within each group keep AI order.
          ordinal = string.format("%s_%03d_%s", is_reviewed and "z" or "a", ai and ai.order or 999, entry.filename),
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

  local ai_previewer = require("telescope.previewers").new_buffer_previewer({
    title = "AI Review Note",
    define_preview = function(self, entry)
      local bufnr = self.state.bufnr
      local winid = self.state.winid
      local ai = M.ai_suggestions and M.ai_suggestions[entry.filename]

      local pwidth = vim.api.nvim_win_get_width(winid)
      local max_col = pwidth - 2

      if not ai then
        local fallback = word_wrap("(no AI description — run :BranchReview aiAugment)", max_col)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, fallback)
        return
      end

      local change_type = ai.change_type or "chore"
      local sep = string.rep("─", max_col)
      local desc_lines = word_wrap(ai.description, max_col)

      local lines = { change_type, sep, "" }
      vim.list_extend(lines, desc_lines)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

      -- Highlights
      vim.api.nvim_buf_add_highlight(bufnr, 0, type_hl[change_type] or "Normal", 0, 0, #change_type)
      vim.api.nvim_buf_add_highlight(bufnr, 0, "Comment", 1, 0, -1)
    end,
  })

  open_with_preview({
    prompt_title = "Modified files — " .. M.comparison_branch,
    initial_mode = "normal",
    sorter = conf.generic_sorter({}),
    previewer = ai_previewer,
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

-- ─── Cicerone intro ──────────────────────────────────────────────────────────

local function show_cicerone_intro(on_close)
  if not M.ai_summary or M.ai_summary == "" then
    on_close()
    return
  end

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)

  local max_col = width - 6 -- 2 indent + 2 margin + 2 border
  local context = M.current_branch .. "  →  " .. M.comparison_branch
  local sep = string.rep("─", max_col)
  local summary_lines = word_wrap(M.ai_summary, max_col)

  local lines = { "  " .. context, "  " .. sep, "" }
  for _, l in ipairs(summary_lines) do
    table.insert(lines, "  " .. l)
  end
  table.insert(lines, "")
  table.insert(lines, "  <CR> open files  ·  <q> skip")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    title = " Cicerone ",
    title_pos = "center",
  })
  vim.wo[win].cursorline = false
  vim.wo[win].scrolloff = 2

  -- Dim the structural lines, body stays Normal
  vim.api.nvim_buf_add_highlight(buf, 0, "Comment", 0, 0, -1) -- context
  vim.api.nvim_buf_add_highlight(buf, 0, "Comment", 1, 0, -1) -- separator
  vim.api.nvim_buf_add_highlight(buf, 0, "Comment", #lines - 1, 0, -1) -- hint

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    on_close()
  end

  local map_opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>", close, map_opts)
  vim.keymap.set("n", "q", close, map_opts)
  vim.keymap.set("n", "<Esc>", close, map_opts)
end

-- ─── AI augmentation ─────────────────────────────────────────────────────────

local function augment_with_ai()
  if not M.enabled then
    vim.notify("Review mode is not ongoing. Start review mode first.", vim.log.levels.WARN)
    return
  end

  local pr_ctx = ""
  local pr_raw = vim.fn.system("gh pr view --json title,body 2>/dev/null")
  if vim.v.shell_error == 0 and pr_raw ~= "" then
    local ok, pr = pcall(vim.json.decode, pr_raw)
    if ok and pr then
      pr_ctx =
        string.format("PR Title: %s\nPR Description:\n%s\n", pr.title or "(no title)", pr.body or "(no description)")
    end
  end

  local prompt = string.format(
    [[
I am doing a code review of branch `%s` against `%s`. You should assist the user to gather all the needed context to perform an exhaustive review of the changes.
%s
Files changed:
%s

Hunks (filename, start line):
%s

If the branch changes are a feature:
    - summary: a recap of the feature flow in the app, to give context on how the feature works before diving in the code
    - file description: how the code fits into the feature flow (from summary), as well as what are the consequences of the changes
if the branch changes are a refactor:
    - summary: is the refactor following any known software engineering pattern? does it follow OUR best practices for the app?(check app docs). What feature flows are affected?
    - file description: what are the consequences of the changes? how do the impacted lines fit in the app flow?
if the branch changes are about docs:
    - summary: short summary of the docs, does it fit with the rest of the docs in the app?
    - file description: short summary of the added docs, does it fit with the rest of the docs in the app?
if the branch changes are about a fix:
    - summary: a recap of the feature flow in the app, to give context on how the feature works before diving in the code. What feature flows are affected by the changes?
    - file description: what are the consequences of the changes? what flows are affected
if the branch changes are about a chore:
    - summary: what app flows are affected? does it follow OUR best practices for the app
    - file description: what are the consequences of the changes? what flows are affected
if the branch changes are something else:
    - summary: what app flows are affected? does it follow OUR best practices for the app
    - file description: what are the consequences of the changes? what flows are affected

Return ONLY a valid JSON object, no markdown, no explanation:
{
  "summary": "<concise bullet point list>",
  "files": [
    {
      "filename": "<exact path>",
      "order": <integer, 1 = highest priority>,
      "change_type": "<feature|fix|refactor|test|chore|docs>",
      "description": "<concise bullet point list>"
    }
  ]
}
Include every file in "files". Order by review priority.
  ]],
    M.current_branch,
    M.comparison_branch,
    pr_ctx,
    vim.inspect(M.files),
    vim.inspect(M.hunks)
  )

  -- ─── Streaming ───────────────────────────────────────────────────────────────

  local win_width = math.min(76, vim.o.columns - 4)
  local status = make_status_float("Claude AI", { width = win_width, height = 14 })
  status.phase("Analyzing")

  local stdout_buf = ""
  local full_result = nil
  local files_seen = 0
  local total_files = #vim.tbl_filter(function(f)
    return f ~= ""
  end, M.files)

  local function process_event(line)
    if line == "" then
      return
    end
    local ok, ev = pcall(vim.json.decode, line)
    if not ok or type(ev) ~= "table" then
      return
    end

    if ev.type == "assistant" then
      local content = (ev.message or {}).content or {}
      for _, item in ipairs(content) do
        if item.type == "thinking" then
          status.phase("Reasoning")
          status.content(item.thinking or "")
        elseif item.type == "text" then
          local n = 0
          for _ in (item.text or ""):gmatch('"filename"') do
            n = n + 1
          end
          if n > files_seen then
            files_seen = n
          end
          status.phase(string.format("Generating  %d / %d files", files_seen, total_files))
          status.content(item.text or "")
        end
      end
    elseif ev.type == "result" then
      full_result = ev.result
    end
  end

  vim.system(
    { "claude", "-p", "--output-format=stream-json", "--include-partial-messages", "--verbose", prompt },
    {
      text = true,
      stdout = function(_, data)
        if not data then
          return
        end
        stdout_buf = stdout_buf .. data
        local lines = vim.split(stdout_buf, "\n", { plain = true })
        stdout_buf = lines[#lines]
        for i = 1, #lines - 1 do
          process_event(lines[i])
        end
      end,
    },
    vim.schedule_wrap(function(result)
      status.close()

      if result.code ~= 0 or not full_result then
        vim.notify("Claude error: " .. (result.stderr or "unknown error"), vim.log.levels.ERROR)
        return
      end

      local json_str = full_result
      json_str = json_str:match("```json%s*(.-)%s*```") or json_str:match("```%s*(.-)%s*```") or json_str
      local start_idx = json_str:find("{")
      local end_idx = #json_str - (json_str:reverse():find("}") or 1) + 1
      json_str = json_str:sub(start_idx, end_idx)

      local ok, parsed = pcall(vim.json.decode, json_str)
      if not ok or type(parsed) ~= "table" then
        vim.notify("Failed to parse Claude response as JSON", vim.log.levels.ERROR)
        return
      end

      M.ai_summary = parsed.summary or ""
      M.ai_suggestions = {}
      for _, s in ipairs(parsed.files or {}) do
        if s.filename then
          M.ai_suggestions[s.filename] = {
            order = s.order or 999,
            change_type = s.change_type or "chore",
            description = s.description or "",
          }
        end
      end

      show_cicerone_intro(open_file_picker)
    end)
  )
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
  M.ai_summary = nil
  M.ai_suggestions = nil
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

local valid_commands = { "start", "stop", "files", "hunksToQfixList", "aiAugment", "cicerone" }

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
  elseif cmd == "aiAugment" then
    augment_with_ai()
  elseif cmd == "cicerone" then
    if not M.ai_summary or M.ai_summary == "" then
      vim.notify("No AI summary yet — run :BranchReview aiAugment first", vim.log.levels.WARN)
      return
    end
    show_cicerone_intro(open_file_picker)
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
  vim.keymap.set("n", "<leader>gra", "<cmd>BranchReview aiAugment<cr>", { desc = "AI overview" })
  vim.keymap.set("n", "<leader>grc", "<cmd>BranchReview cicerone<cr>", { desc = "open cicerone summary" })
end

return M
