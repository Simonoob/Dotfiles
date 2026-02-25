local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local themes = require("telescope.themes")

local M = {
  enabled = false,
  comparison_branch = nil,
  files = nil,
  hunks = nil,
  ai_suggestions = nil, -- map: filename -> { order, description }
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

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function get_current_branch()
  local branch = vim.fn.system("git branch --show-current | tr -d '\n'")
  return branch
end

-- Add this to your statusline setup
-- %{%v:lua.require'branch-review'.get_statusline_indicator()%}
function M.get_statusline_indicator()
  if M.enabled then
    return string.format("[Review 󰘬 %s → %s]", M.current_branch, M.comparison_branch)
  else
    return ""
  end
end

local function stop_review_mode(force)
  if not M.enabled and not force then
    vim.notify("Review mode is not ongoing", vim.log.levels.WARN)
    return
  end

  -- Reset Gitsigns base on all open buffers
  require("gitsigns").reset_base("global")
  require("gitsigns").toggle_word_diff()

  -- Close and clear quickfix list
  vim.cmd("Trouble qflist close")
  vim.fn.setqflist({}, "r")

  -- Reset state
  M.enabled = false
  M.comparison_branch = nil
  M.current_branch = nil
  M.ai_suggestions = nil

  vim.notify("Review mode stopped", vim.log.levels.INFO)
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

local function handle_gitsigns()
  local common_commit = vim.system({ "git", "merge-base", M.comparison_branch, M.current_branch }):wait()
  vim.fn.execute(string.format("Gitsigns change_base %s global", common_commit.stdout))
end

local function get_all_modified_chunks(comparison_branch)
  local diff_output = vim.fn.system("git diff " .. comparison_branch .. "...")
  local lines = vim.split(diff_output, "\n")

  local modified_chunks = {}
  local current_file = nil

  for _, line in ipairs(lines) do
    local file_match = line:match("^%+%+%+ b/(.+)$")
    if file_match then
      current_file = file_match
    end

    local chunk_match = line:match("^@@ %-[%d,]+ %+([%d,]+) @@")
    if chunk_match and current_file then
      local line_info = vim.split(chunk_match, ",")
      table.insert(modified_chunks, {
        filename = current_file,
        lnum = tonumber(line_info[1]),
      })
    end
  end

  return modified_chunks
end

local function add_chunks_to_quickfix()
  require("gitsigns").setqflist("all")
end

local function get_all_modified_files(comparison_branch)
  local output = vim.fn.system("git diff --name-only --merge-base " .. comparison_branch)
  return vim.split(output, "\n")
end

-- ─── Pickers ─────────────────────────────────────────────────────────────────

local function telescope_select_branch(branches, on_select_fn)
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
          vim.cmd("BranchReview stop")
          return
        end
        on_select_fn(selected.value)
      end)
      map("n", "<Esc>", function()
        actions.close(prompt_bufnr)
        stop_review_mode(true)
      end)
      return true
    end,
  })
end

local function open_modified_files()
  if M.hunks == nil or #M.hunks == 0 then
    vim.notify("No modified files found - make sure that review mode is ongoing", vim.log.levels.WARN)
    return
  end

  -- Index chunks by file
  local file_chunks = {}
  for _, item in ipairs(M.hunks) do
    if not file_chunks[item.filename] then
      file_chunks[item.filename] = { count = 0, locations = {} }
    end
    file_chunks[item.filename].count = file_chunks[item.filename].count + 1
    table.insert(file_chunks[item.filename].locations, item)
  end

  -- Build ordered file entries
  local file_entries = {}
  for _, file in ipairs(M.files) do
    if file ~= "" then
      table.insert(file_entries, {
        filename = file,
        chunks = file_chunks[file] or { count = 0, locations = {} },
      })
    end
  end

  -- Sort by AI-suggested order if available
  if M.ai_suggestions then
    table.sort(file_entries, function(a, b)
      local oa = (M.ai_suggestions[a.filename] or {}).order or 999
      local ob = (M.ai_suggestions[b.filename] or {}).order or 999
      return oa < ob
    end)
  end

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { remaining = true },
      { width = 12 },
    },
  })

  local ai_previewer = require("telescope.previewers").new_buffer_previewer({
    title = "AI Review Note",
    define_preview = function(self, entry)
      local ai = M.ai_suggestions and M.ai_suggestions[entry.filename]
      local lines = ai and { ai.description } or { "(no AI description)" }
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.wo[self.state.winid].wrap = true
    end,
  })

  open_with_preview({
    prompt_title = "Modified files — " .. M.comparison_branch,
    initial_mode = "normal",
    sorter = conf.generic_sorter({}),
    previewer = ai_previewer,
    finder = finders.new_table({
      results = file_entries,
      entry_maker = function(entry)
        local ai = M.ai_suggestions and M.ai_suggestions[entry.filename]
        local parts = vim.split(entry.filename, "/")
        local short_name = #parts > 1
            and ("…" .. parts[#parts - 1] .. "/" .. parts[#parts])
            or entry.filename
        return {
          value = entry,
          display = function()
            return displayer({
              short_name,
              { "[" .. entry.chunks.count .. " hunks]", "Comment" },
            })
          end,
          ordinal = string.format("%03d_%s", ai and ai.order or 999, entry.filename),
          filename = entry.filename,
        }
      end,
    }),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selected = action_state.get_selected_entry()
        if not selected then
          vim.notify("No file selected", vim.log.levels.WARN)
          return
        end
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

-- ─── AI augmentation ─────────────────────────────────────────────────────────

local function augment_with_ai()
  if not M.enabled then
    vim.notify("Review mode is not ongoing. Start review mode first.", vim.log.levels.WARN)
    return
  end

  vim.notify("Fetching AI review suggestions...", vim.log.levels.INFO)

  -- Get PR description if available via gh CLI
  local pr_ctx = ""
  local pr_raw = vim.fn.system("gh pr view --json title,body 2>/dev/null")
  if vim.v.shell_error == 0 and pr_raw ~= "" then
    local ok, pr = pcall(vim.json.decode, pr_raw)
    if ok and pr then
      pr_ctx = string.format("PR Title: %s\nPR Description:\n%s\n", pr.title or "(no title)", pr.body or "(no description)")
    end
  end

  local prompt = string.format(
    [[
I am doing a code review of branch `%s` against `%s`.
%s
Files changed:
%s

Hunks (filename, start line):
%s

Return ONLY a valid JSON array, no markdown, no explanation. Each element:
{ "filename": "<exact path>", "description": "<one sentence summary of changes in this file>", "order": <integer, 1 = highest priority> }
Include every file. Order by review priority.
    ]],
    M.current_branch,
    M.comparison_branch,
    pr_ctx,
    vim.inspect(M.files),
    vim.inspect(M.hunks)
  )

  local start_time = vim.uv.now()
  local timer = vim.uv.new_timer()
  timer:start(1000, 1000, vim.schedule_wrap(function()
    local elapsed = math.floor((vim.uv.now() - start_time) / 1000)
    vim.notify(string.format("Fetching AI review suggestions... (%ds)", elapsed), vim.log.levels.INFO)
  end))

  vim.system({ "claude", "-p", prompt }, { text = true }, function(result)
    timer:stop()
    timer:close()

    local raw = result.stdout or ""
    local json_str = raw:match("```json%s*(.-)%s*```") or raw:match("```%s*(.-)%s*```") or raw
    local start_idx = json_str:find("%[")
    local end_idx = #json_str - (json_str:reverse():find("%]") or 1) + 1
    json_str = json_str:sub(start_idx, end_idx)

    local ok, suggestions = pcall(vim.json.decode, json_str)
    if not ok or type(suggestions) ~= "table" then
      vim.schedule(function()
        vim.notify("Failed to parse AI response as JSON", vim.log.levels.ERROR)
      end)
      return
    end

    M.ai_suggestions = {}
    for _, s in ipairs(suggestions) do
      if s.filename then
        M.ai_suggestions[s.filename] = { order = s.order or 999, description = s.description or "" }
      end
    end

    vim.schedule(function()
      vim.notify("AI suggestions ready — opening file picker", vim.log.levels.INFO)
      open_modified_files()
    end)
  end)
end

-- ─── Review lifecycle ────────────────────────────────────────────────────────

local function on_branch_selected(comparison_branch)
  vim.notify("Pulling " .. comparison_branch .. "...", vim.log.levels.INFO)
  vim.fn.system("git fetch origin " .. comparison_branch .. ":" .. comparison_branch)

  M.files = get_all_modified_files(comparison_branch)
  M.hunks = get_all_modified_chunks(comparison_branch)

  handle_gitsigns()
  require("gitsigns").toggle_word_diff()

  open_modified_files()
end

local function start_review_mode()
  if M.enabled then
    vim.notify("Review mode is already ongoing", vim.log.levels.WARN)
    return
  end

  local branches = get_branches_list()
  telescope_select_branch(branches, function(selected_branch)
    M.comparison_branch = selected_branch
    M.current_branch = get_current_branch()
    M.enabled = true
    on_branch_selected(selected_branch)
  end)
end

-- ─── Command & keymaps ───────────────────────────────────────────────────────

local valid_commands = { "start", "stop", "files", "hunksToQfixList", "aiAugment" }

vim.api.nvim_create_user_command("BranchReview", function(opts)
  local command = opts.args
  if not vim.tbl_contains(valid_commands, command) then
    vim.notify("Invalid command. Valid commands are: " .. vim.inspect(valid_commands), vim.log.levels.ERROR)
    return
  end

  if command == "start" then
    start_review_mode()
  elseif command == "stop" then
    stop_review_mode()
  elseif command == "files" then
    open_modified_files()
  elseif command == "hunksToQfixList" then
    add_chunks_to_quickfix()
  elseif command == "aiAugment" then
    augment_with_ai()
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
end

return M
