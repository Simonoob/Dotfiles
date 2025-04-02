local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local dropdown = require("telescope.themes").get_dropdown()

local branchReview = {
	enabled = false,
	comparison_branch = nil,
}

local function get_current_branch()
	local branch = vim.fn.system("git branch --show-current | tr -d '\n'")
	return branch
end
local original_statusline = vim.o.statusline
local function update_status_line(enabled)
	enabled = enabled == nil and branchReview.enabled or enabled
	if enabled then
		vim.o.statusline = "[BranchReview] checking "
			.. get_current_branch()
			.. " against "
			.. (branchReview.comparison_branch or "???")
	else
		vim.o.statusline = original_statusline
	end
end

local function dropdown_pick_telescope(opts)
	local telescope_ok = pcall(require, "telescope.builtin")
	if not telescope_ok then
		vim.notify("Telescope is required for this function", vim.log.levels.ERROR)
		return
	end

	opts = opts
		or {
			prompt_title = "Pick file",
			initial_mode = "normal",
			finder = finders.new_table({
				results = { "change `finder` with your function" },
			}),
			sorter = conf.generic_sorter({}),
		}

	pickers.new(dropdown, opts):find()
end

local function stop_review_mode(force)
	if not branchReview.enabled and not force then
		vim.notify("Review mode is not enabled", vim.log.levels.WARN)
		return
	end

	-- Reset Gitsigns base on all open buffers
	vim.cmd("Gitsigns reset_base global")

	-- Close and clear quickfix list
	vim.cmd("Trouble qflist close")
	vim.fn.setqflist({}, "r")

	-- Reset state
	branchReview.enabled = false
	branchReview.comparison_branch = nil
	update_status_line(false)

	vim.notify("Review mode stopped", vim.log.levels.INFO)
end

local function telescope_select_branch(branches, on_select_fn)
	-- Create picker to select branch
	dropdown_pick_telescope({
		prompt_title = "Select branch to compare against:",
		initial_mode = "normal",
		sorter = require("telescope.config").values.generic_sorter({}),
		finder = require("telescope.finders").new_table({
			results = branches,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry,
					ordinal = entry,
					filename = entry,
				}
			end,
		}),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selected = action_state.get_selected_entry()

				print("selected.value", selected.value)
				if not selected.value then
					vim.notify("No branch selected", vim.log.levels.ERROR)
					vim.cmd("BranchReview stop")
					return
				end

				on_select_fn(selected.value)
			end)
			map("n", "<Esc>", function()
				vim.notify("No branch selected", vim.log.levels.ERROR)
				actions.close(prompt_bufnr)
				stop_review_mode(true)
			end)
			return true
		end,
	})
end

local function get_branches_list()
	-- Get list of branches
	local branches_raw = vim.fn.systemlist("git branch --format='%(refname:short)'")
	local branches = {}

	-- Always include main and master if they exist
	table.insert(branches, "main")
	table.insert(branches, "master")

	-- Add other branches
	for _, branch in ipairs(branches_raw) do
		table.insert(branches, branch)
	end

	-- Remove duplicates
	local unique_branches = {}
	local seen = {}
	for _, branch in ipairs(branches) do
		if not seen[branch] then
			seen[branch] = true
			table.insert(unique_branches, branch)
		end
	end
	return unique_branches
end

local function handle_gitsigns(modified_files, comparison_branch)
	-- Configure Gitsigns to use the selected branch as base
	vim.cmd("Gitsigns change_base " .. get_current_branch() .. "..." .. comparison_branch .. " global") -- TODO: fixme pls it doesn't show any diff atm
	vim.cmd("Gitsigns refresh")
end

local function get_modified_chunks(comparison_branch)
	local diff_output = vim.fn.system("git diff --merge-base " .. comparison_branch .. " --unified=0")
	local lines = vim.split(diff_output, "\n")

	local modified_chunks = {}
	local current_file = nil

	for _, line in ipairs(lines) do
		-- Check for file header line
		local file_match = line:match("^%+%+%+ b/(.+)$")
		if file_match then
			current_file = file_match
		end

		-- Check for chunk header line
		local chunk_match = line:match("^@@ %-[%d,]+ %+([%d,]+) @@")
		if chunk_match and current_file then
			local line_info = vim.split(chunk_match, ",")
			local start_line = tonumber(line_info[1])

			table.insert(modified_chunks, {
				filename = current_file,
				lnum = start_line,
				text = line:match("@@ .+ @@(.*)$") or "Modified chunk",
			})
		end
	end

	return modified_chunks
end

local function add_modified_chunks_to_quickfix(modified_chunks)
	vim.fn.setqflist({}, "r")
	vim.fn.setqflist(modified_chunks)
end

local function open_quickfix_list(qf_items, modified_files, comparison_branch)
	if #qf_items == 0 then
		vim.notify(
			"Found " .. #modified_files .. " modified files with " .. #qf_items .. " changed chunks",
			vim.log.levels.INFO
		)
		return
	end

	vim.notify(
		"Found " .. #modified_files .. " modified files with " .. #qf_items .. " changed chunks",
		vim.log.levels.INFO
	)

	-- Create a table for file entries with chunk information
	local file_entries = {}
	local file_chunks = {}

	-- Count chunks per file and organize chunk info
	for _, item in ipairs(qf_items) do
		if not file_chunks[item.filename] then
			file_chunks[item.filename] = {
				count = 0,
				locations = {},
			}
		end
		file_chunks[item.filename].count = file_chunks[item.filename].count + 1
		table.insert(file_chunks[item.filename].locations, item)
	end

	-- Create entries for selection
	for _, file in ipairs(modified_files) do
		if file ~= "" then
			table.insert(file_entries, {
				filename = file,
				chunks = file_chunks[file] or { count = 0, locations = {} },
			})
		end
	end

	dropdown_pick_telescope({
		prompt_title = "Modified files against " .. comparison_branch .. ":",
		initial_mode = "normal",
		sorter = require("telescope.config").values.generic_sorter({}),
		finder = require("telescope.finders").new_table({
			results = file_entries,

			entry_maker = function(entry)
				return {
					value = entry,
					display = function()
						local function split(s, delimiter)
							local result = {}
							for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
								table.insert(result, match)
							end
							return result
						end

						local parts = split(entry.filename, "/")
						if #parts > 1 then
							return "..." .. parts[#parts - 1] .. "/" .. parts[#parts]
						else
							return entry.filename
						end
					end,
					ordinal = entry.filename,
					filename = entry.filename,
				}
			end,
		}),

		previewer = previewers.new_buffer_previewer({
			title = "Changes Summary",
			define_preview = function(self, entry, status)
				if entry.value.chunks.count > 0 then
					vim.api.nvim_buf_set_lines(
						self.state.bufnr,
						0,
						1,
						false,
						{ "# Modified Chunks: " .. entry.value.chunks.count }
					)
				else
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 1, false, { "no chunk information available" })
				end
			end,
		}),

		attach_mappings = function(prompt_bufnr, map)
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")

			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selected = action_state.get_selected_entry()

				if not selected then
					vim.notify("No file selected", vim.log.levels.WARN)
					return
				end

				-- Open the selected file
				vim.cmd("edit " .. selected.value.filename)
			end)
			return true
		end,
	})
end

local function get_modified_files(comparison_branch)
	local modified_files_output = vim.fn.system("git diff --name-only --merge-base " .. comparison_branch)
	local modified_files = vim.split(modified_files_output, "\n")
	return modified_files
end

local function on_branch_selected(comparison_branch)
	print(branchReview.comparison_branch)
	-- Pull the selected branch
	vim.notify("Pulling " .. comparison_branch .. "...", vim.log.levels.INFO)
	vim.fn.system("git fetch origin " .. comparison_branch .. ":" .. comparison_branch)

	local modified_files = get_modified_files(comparison_branch)
	local modified_chunks = get_modified_chunks(comparison_branch)

	add_modified_chunks_to_quickfix(modified_chunks)

	open_quickfix_list(modified_chunks, modified_files, comparison_branch)

	handle_gitsigns(modified_files, comparison_branch)
end

local function start_review_mode()
	if branchReview.enabled then
		vim.notify("Review mode is already enabled", vim.log.levels.WARN)
		return
	end

	local branches = get_branches_list()
	telescope_select_branch(branches, function(selected_branch)
		branchReview.enabled = true
		branchReview.comparison_branch = selected_branch
		update_status_line(true)
		on_branch_selected(selected_branch)
	end)
end

local valid_commands = { "start", "stop" }

-- Function to review changes against a selected branch
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
	else
		vim.notify("Invalid command. Valid commands are: " .. vim.inspect(valid_commands), vim.log.levels.ERROR)
	end
end, {
	nargs = 1,
	desc = "Git branch review mode",
	complete = function(ArgLead, CmdLine, CursorPos)
		-- Check if a valid command is already in the command line
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

branchReview.setup = function()
	vim.keymap.set("n", "<leader>gr", function()
		if branchReview.enabled then
			vim.cmd("BranchReview stop")
			update_status_line(false)
		else
			vim.cmd("BranchReview start")
			update_status_line(true)
		end
	end, { desc = "Git branch Review toggle" })
end

return branchReview
