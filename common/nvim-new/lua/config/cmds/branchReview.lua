local function telescope_select_branch(branches, on_select_fn)
	-- Get local branches using telescope
	local telescope_ok, telescope = pcall(require, "telescope.builtin")
	if not telescope_ok then
		vim.notify("Telescope is required for this function", vim.log.levels.ERROR)
		return
	end

	-- Create picker to select branch
	vim.ui.select(branches, {
		prompt = "Select branch to compare against:",
		telescope = {
			initial_mode = "normal",
		},
	}, function(selected_branch)
		if not selected_branch then
			vim.notify("No branch selected", vim.log.levels.WARN)
			return
		end
		on_select_fn(selected_branch)
	end)
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
	vim.cmd("Gitsigns change_base " .. comparison_branch .. " global")
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

	local previewers = require("telescope.previewers")
	-- Define our custom telescope config for vim.ui.select
	local telescope_config = {
		initial_mode = "normal",
		previewer = previewers.new_buffer_previewer({
			title = "Change Summary",
			define_preview = function(self, entry, status)
				local content = {}
				table.insert(content, "")
				table.insert(content, "Total chunks changed: " .. entry.value.chunks.count)
				table.insert(content, "")

				if entry.value.chunks.count > 0 then
					vim.api.nvim_buf_set_lines(
						self.state.bufnr,
						0,
						3,
						false,
						{ "# Total chunks: " .. entry.value.chunks.count, "", "## Changes:" }
					)
					for i, loc in ipairs(entry.value.chunks.locations) do
						vim.api.nvim_buf_set_lines(self.state.bufnr, i + 2, i + 3, false, { "- Line " .. loc.lnum })
					end
				else
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 1, false, { "no chunk information available" })
				end
				return content
			end,
		}),
	}

	vim.ui.select(file_entries, {
		prompt = "Modified files against " .. comparison_branch .. ":",
		format_item = function(item)
			return item.filename
		end,
		telescope = telescope_config,
	}, function(selected)
		if not selected then
			vim.notify("No file selected", vim.log.levels.WARN)
			return
		end

		-- Open the selected file
		vim.cmd("edit " .. selected.filename)
	end)
end

local function get_modified_files(comparison_branch)
	local modified_files_output = vim.fn.system("git diff --name-only --merge-base " .. comparison_branch)
	local modified_files = vim.split(modified_files_output, "\n")
	return modified_files
end

-- Initialize global gitReviewMode if it doesn't exist
if not _G.gitReviewMode then
	_G.gitReviewMode = {
		enabled = false,
		current_branch = nil,
	}
end

local function on_branch_selected(comparison_branch)
	-- Pull the selected branch
	vim.notify("Pulling " .. comparison_branch .. "...", vim.log.levels.INFO)
	vim.fn.system("git pull origin " .. comparison_branch)

	local modified_files = get_modified_files(comparison_branch)
	local modified_chunks = get_modified_chunks(comparison_branch)

	add_modified_chunks_to_quickfix(modified_chunks)

	open_quickfix_list(modified_chunks, modified_files, comparison_branch)

	handle_gitsigns(modified_files, comparison_branch)
end

local function start_review_mode()
	if _G.gitReviewMode.enabled then
		vim.notify("Review mode is already enabled", vim.log.levels.WARN)
		return
	end

	local branches = get_branches_list()
	telescope_select_branch(branches, function(selected_branch)
		_G.gitReviewMode.enabled = true
		_G.gitReviewMode.current_branch = selected_branch
		on_branch_selected(selected_branch)
	end)
end

local function stop_review_mode()
	if not _G.gitReviewMode.enabled then
		vim.notify("Review mode is not enabled", vim.log.levels.WARN)
		return
	end

	-- Reset Gitsigns base on all open buffers
	local buffers = vim.api.nvim_list_bufs()
	for _, buf in ipairs(buffers) do
		if vim.api.nvim_buf_is_loaded(buf) then
			vim.api.nvim_buf_call(buf, function()
				vim.cmd("Gitsigns reset_base")
			end)
		end
	end

	-- Clear the autocommand group
	vim.api.nvim_del_augroup_by_name("GitSignsModifiedFiles")

	-- Close and clear quickfix list
	vim.cmd("Trouble qflist close")
	vim.fn.setqflist({}, "r")

	-- Reset state
	_G.gitReviewMode.enabled = false
	_G.gitReviewMode.current_branch = nil

	vim.notify("Review mode stopped", vim.log.levels.INFO)
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
