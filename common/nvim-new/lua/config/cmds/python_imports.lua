-- lua/missing_imports/init.lua

local M = {}

-- Function to find the project root by searching upwards for pyproject.toml
local function find_project_root()
  local path = vim.fn.getcwd()
  while path ~= "/" do
    if vim.fn.filereadable(path .. "/pyproject.toml") == 1 then
      return path
    end
    path = vim.fn.fnamemodify(path, ":h")
  end
  return nil -- No pyproject.toml found
end

-- Function to get LSP diagnostics for the current buffer
local function get_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  -- local client = vim.lsp.get_active_clients({ bufnr = bufnr })[1] -- Get the first active LSP client
  -- if not client then
  --     vim.notify("No active LSP client for this buffer.", vim.log.levels.WARN)
  --     return {}
  -- end

  -- This is a simplified way to get diagnostics.
  -- A more robust approach might involve listening to diagnostic events
  -- or using a specific LSP client's API if available.
  -- For now, we'll rely on the built-in vim.diagnostic.get
  local diagnostics = vim.diagnostic.get(bufnr)
  return diagnostics or {}
end

-- Function to identify undefined names from diagnostics using code and range
local function identify_undefined_names(diagnostics)
  local undefined_names = {}
  local bufnr = vim.api.nvim_get_current_buf()

  for _, diag in ipairs(diagnostics) do
    -- Check if the diagnostic is an ERROR and has a code property
    if diag.severity == vim.diagnostic.severity.ERROR and diag.code then
      -- Check for specific diagnostic codes that indicate an undefined variable.
      -- The exact code might vary depending on the LSP server (e.g., Pyright, pylsp).
      -- 'reportUndefinedVariable' is a common one for Pyright.
      -- You might need to add other codes here or make this configurable.
      if diag.code == "reportUndefinedVariable" or diag.code == "undefined-variable" then -- Added a potential generic code
        -- Use the diagnostic range to get the exact text of the undefined name
        local start_row = diag.lnum -- lnum is 0-indexed line
        local start_col = diag.col -- col is 0-indexed character
        local end_row = diag.end_lnum -- end_lnum is 0-indexed line
        local end_col = diag.end_col -- end_col is 0-indexed character

        -- nvim_buf_get_text expects 0-indexed start/end row/col
        local name_text = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})

        -- nvim_buf_get_text returns a list of lines, join them
        local name = table.concat(name_text, "\n")

        if name and name ~= "" then
          undefined_names[name] = true -- Use a table as a set to avoid duplicates
        end
      end
    end
  end

  local names_list = {}
  for name, _ in pairs(undefined_names) do
    table.insert(names_list, name)
  end
  return names_list
end

-- Function to find possible import paths for undefined names using Treesitter and ripgrep
local function find_possible_imports(undefined_names, project_root)
  if not project_root then
    vim.notify("Could not find project root (pyproject.toml). Cannot search for imports.", vim.log.levels.WARN)
    return {}
  end

  local possible_imports = {}
  local python_files = {}

  -- Use ripgrep to find all Python files in the project root
  -- rg --files --glob '*.py' <project_root>
  local job_id = vim.fn.jobstart({ "rg", "--files", "--glob", "*.py", project_root }, {
    on_stdout = function(chan, data, name)
      -- Append each line of output (each file path) to the python_files table
      for _, line in ipairs(data) do
        if line and line ~= "" then
          table.insert(python_files, line)
        end
      end
    end,
    on_stderr = function(chan, data, name)
      -- Log any errors from ripgrep
      vim.notify("Ripgrep error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
    end,
    on_exit = function(chan, exit_code, name)
      if exit_code ~= 0 then
        vim.notify("Ripgrep exited with code: " .. exit_code, vim.log.levels.WARN)
      end
      -- Ripgrep has finished, now process the found files
      if #python_files == 0 then
        vim.notify("No Python files found in the project using ripgrep.", vim.log.levels.INFO)
        return {} -- Early return if no files found
      end

      -- Create a set of undefined names for quicker lookup
      local undefined_set = {}
      for _, undefined_name in ipairs(undefined_names) do
        undefined_set[undefined_name] = true
        possible_imports[undefined_name] = {} -- Initialize entry for each name
      end

      vim.notify(
        "Searching " .. #python_files .. " Python files for definitions using Treesitter...",
        vim.log.levels.INFO
      )

      for _, file_path in ipairs(python_files) do
        local relative_path = file_path:sub(#project_root + 2) -- Get path relative to project root, remove leading '/'
        local module_path = relative_path:gsub("/", "."):gsub("%.py$", "") -- Convert path to module format (e.g., my_package.my_module)

        local parser = vim.treesitter.get_parser(nil, "python", { path = file_path })
        if not parser then
          vim.notify(
            "Could not get Treesitter parser for: " .. file_path .. ". Ensure you have run :TSInstall python",
            vim.log.levels.WARN
          )
          goto continue_files
        end

        local tree = parser:parse()[1] -- Get the first (and usually only) tree
        if not tree then
          vim.notify("Could not parse file with Treesitter: " .. file_path, vim.log.levels.WARN)
          goto continue_files
        end

        local root = tree:root()

        -- Define Treesitter queries to find definitions
        -- We are looking for identifiers that are names of function or class definitions
        local queries = {
          function_definition = "(function_definition name: (identifier) @name)",
          class_definition = "(class_definition name: (identifier) @name)",
          -- Add more queries for other definition types if needed (e.g., variable assignments)
          -- variable_assignment = "(assignment left: (identifier) @name)" -- This needs careful handling to only get top-level
        }

        for query_name, query_string in pairs(queries) do
          local query = vim.treesitter.query.parse("python", query_string)
          if query then
            -- Use iter_captures instead of iter_matches
            for id, node in query:iter_captures(root, file_path, 0, -1) do -- Iterate over the whole file (0 to -1 lines)
              -- Ensure the capture is the 'name' capture
              if query.captures[id] == "name" then
                -- Pass file_path as the source and {} for options
                -- The node should be valid here
                local node_text = vim.treesitter.get_node_text(node, file_path, {})
                local defined_name = node_text

                if defined_name and undefined_set[defined_name] then
                  -- Found a definition for an undefined name
                  local import_path = module_path .. "." .. defined_name
                  -- Avoid adding duplicate import paths for the same name
                  local already_added = false
                  for _, existing_import in ipairs(possible_imports[defined_name]) do
                    if existing_import == import_path then
                      already_added = true
                      break
                    end
                  end
                  if not already_added then
                    table.insert(possible_imports[defined_name], import_path)
                    print("    Added possible import:", import_path, "for", defined_name) -- Debug print for added import
                  end
                end
              end
            end
          else
            vim.notify("Could not parse Treesitter query: " .. query_name, vim.log.levels.WARN)
          end
        end

        ::continue_files:: -- Label for goto
      end

      -- Filter out names for which no imports were found
      local resolvable_imports = {}
      for name, imports in pairs(possible_imports) do
        if #imports > 0 then
          resolvable_imports[name] = imports
        end
      end

      -- Now that we have the resolvable imports, we need to trigger the next step
      -- This requires restructuring the main logic to be asynchronous after ripgrep finishes.
      -- For now, we'll just return, but the next step (ambiguity resolution and adding imports)
      -- needs to be moved into this callback or handled asynchronously.
      vim.notify("Ripgrep search finished. Processing results...", vim.log.levels.INFO)

      -- The rest of the add_missing_imports function logic needs to go here or be called from here
      -- This demonstrates the challenge of mixing synchronous and asynchronous operations.
      -- For a fully functional version, the ambiguity resolution and import addition
      -- should be triggered after this callback finishes.
      M.process_found_imports(resolvable_imports, undefined_names)
    end,
  })

  -- Since ripgrep is asynchronous, we return an empty table immediately.
  -- The actual processing will happen in the on_exit callback.
  return {}
end

-- New function to process the imports found by ripgrep (made public for the callback)
function M.process_found_imports(resolvable_imports, undefined_names)
  if vim.tbl_isempty(resolvable_imports) then
    vim.notify("Could not find matching imports in the project.", vim.log.levels.INFO)
    return
  end

  vim.notify(
    "Found possible imports for: " .. table.concat(vim.tbl_keys(resolvable_imports), ", "),
    vim.log.levels.INFO
  )

  -- 3. Add import statements
  local imports_to_add = {}
  local ambiguous_imports = {}

  for name, imports in pairs(resolvable_imports) do
    if #imports == 1 then
      -- Only one option, add directly
      local import_path = imports[1]
      -- Construct the import statement: from module.path import name
      local parts = vim.split(import_path, "%.")
      local imported_name = table.remove(parts) -- Get the last part (the name)
      local module_path = table.concat(parts, ".")
      table.insert(imports_to_add, "from " .. module_path .. " import " .. imported_name)
    else
      -- Multiple options, need user selection
      table.insert(ambiguous_imports, { name = name, imports = imports })
    end
  end

  -- Process ambiguous imports sequentially using vim.ui.select
  local function process_next_ambiguous()
    if #ambiguous_imports > 0 then
      local current_ambiguous = table.remove(ambiguous_imports, 1)
      local name = current_ambiguous.name
      local imports = current_ambiguous.imports

      vim.ui.select(imports, {
        prompt = "Select import for '" .. name .. "':",
        format_item = function(item)
          return item
        end, -- Display the full import path
      }, function(selected_import_path)
        if selected_import_path then
          -- Construct the import statement: from module.path import name
          local parts = vim.split(selected_import_path, "%.")
          local imported_name = table.remove(parts) -- Get the last part (the name)
          local module_path = table.concat(parts, ".")
          table.insert(imports_to_add, "from " .. module_path .. " import " .. imported_name)
        end
        -- Process the next ambiguous import
        process_next_ambiguous()
      end)
    else
      -- All ambiguous imports processed, add the imports to the buffer
      if #imports_to_add > 0 then
        add_imports_to_buffer(imports_to_add)
      else
        vim.notify("No imports selected or automatically resolved.", vim.log.levels.INFO)
      end
    end
  end

  -- Start processing ambiguous imports
  process_next_ambiguous()
end

-- Function to add import statements to the buffer
local function add_imports_to_buffer(imports_to_add)
  local bufnr = vim.api.nvim_get_current_buf()
  local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Find the line number after the last existing import statement
  -- Or 0 if no imports are found
  local insert_line = 0
  for i, line in ipairs(current_lines) do
    -- Basic check for import statements (can be improved)
    if line:match("^%s*import%s+") or line:match("^%s*from%s+") then
      insert_line = i
    end
  end

  -- Prepare the lines to insert
  local lines_to_insert = {}
  -- Add a newline after existing imports if necessary
  if insert_line > 0 and current_lines[insert_line]:match("%S") then
    table.insert(lines_to_insert, "")
    insert_line = insert_line + 1 -- Insert after the newline
  end

  for _, import_statement in ipairs(imports_to_add) do
    table.insert(lines_to_insert, import_statement)
  end

  -- Add a newline after the inserted imports if the next line is not empty
  if #current_lines > insert_line and current_lines[insert_line]:match("%S") then
    table.insert(lines_to_insert, "")
  end

  -- Insert the lines into the buffer
  vim.api.nvim_buf_set_lines(bufnr, insert_line, insert_line, false, lines_to_insert)

  vim.notify("Added " .. #imports_to_add .. " import statement(s).", vim.log.levels.INFO)
end

-- Main function to find and add missing imports
function M.add_missing_imports()
  -- 0. Be active only in python files
  if vim.bo.filetype ~= "python" then
    vim.notify("MissingImports only works in Python files.", vim.log.levels.INFO)
    return
  end

  vim.notify("Scanning for missing imports...", vim.log.levels.INFO)

  -- 1. Scan the current buffer for missing imports (using LSP diagnostics)
  local diagnostics = get_diagnostics()
  local undefined_names = identify_undefined_names(diagnostics)

  if #undefined_names == 0 then
    vim.notify("No missing imports found.", vim.log.levels.INFO)
    return
  end

  vim.notify("Found potential missing names: " .. table.concat(undefined_names, ", "), vim.log.levels.INFO)

  -- 2. Verify possible imports
  local project_root = find_project_root()
  -- find_possible_imports now triggers the next step asynchronously via its callback
  find_possible_imports(undefined_names, project_root)

  -- The rest of the logic that depends on resolvable_imports has been moved
  -- to the M.process_found_imports function, which is called from the
  -- on_exit callback of jobstart.
end

--- Setup function for the plugin
-- This function is called by the user in their init.lua
-- It defines the user command :MissingImports
function M.setup(opts)
  opts = opts or {} -- Allow for future configuration options

  vim.api.nvim_create_user_command("MissingImports", function()
    M.add_missing_imports()
  end, {
    desc = "Find and add missing Python imports based on LSP diagnostics",
    nargs = 0, -- The command takes no arguments
  })
end

return M
