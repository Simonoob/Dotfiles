local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values

local M = {}

local find_files_glob = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()

  local finder = finders.new_async_job({
    command_generator = function(prompt)
      prompt = prompt or ""
      local args = { "rg", "--files", "--color=never" }

      table.insert(args, "--iglob")
      -- TODO: implement the --exact fuction
      -- if string.find(prompt, " --exact") then
      --   table.insert(args, string.gsub(prompt, " %-%-exact", "")[1])
      -- else
      table.insert(args, string.format("**/*%s*", prompt))
      -- end

      table.insert(args, opts.cwd)

      return args
    end,
    entry_maker = make_entry.gen_from_file(opts),
    cwd = opts.cwd,
  })

  pickers
    .new(opts, {
      debounce = 100,
      prompt_title = "Find Files (' --exact' for exact glob)",
      finder = finder,
      previewer = conf.file_previewer(opts),
      sorter = require("telescope.sorters").empty(),
    })
    :find()
end

M.setup = function()
  vim.keymap.set("n", "<leader>ff", find_files_glob, { desc = "Find Files with glob opts" })
  vim.keymap.set("n", "<leader> ", find_files_glob, { desc = "Find Files with glob opts" })
end

return M
