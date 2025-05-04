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
  -- Using vim.diagnostic.get is generally sufficient
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
        local name = table.concat(name_text, "\n") -- Join without newline for single identifier

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

-- Function to find possible import paths using Treesitter and ripgrep (Temporary Buffer Method)
local function find_possible_imports(undefined_names, project_root)
  if not project_root then
    vim.notify("Could not find project root (pyproject.toml). Cannot search for imports.", vim.log.levels.WARN)
    return {}
  end

  local possible_imports = {}
  local python_files = {}

  -- Use ripgrep to find all Python files
  local job_id = vim.fn.jobstart({ "rg", "--files", "--glob", "*.py", project_root }, {
    on_stdout = function(_, data, _)
      for _, line in ipairs(data) do
        if line and line ~= "" then
          table.insert(python_files, line)
        end
      end
    end,
    on_stderr = function(_, data, _)
      vim.notify("Ripgrep error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
    end,
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        vim.notify("Ripgrep exited with code: " .. exit_code, vim.log.levels.WARN)
      end
      if #python_files == 0 then
        vim.notify("No Python files found in the project using ripgrep.", vim.log.levels.INFO)
        M.process_found_imports({}, undefined_names)
        return
      end

      local undefined_set = {}
      for _, undefined_name in ipairs(undefined_names) do
        undefined_set[undefined_name] = true
        possible_imports[undefined_name] = {}
      end

      vim.notify(
        "Searching " .. #python_files .. " Python files for definitions using Treesitter...",
        vim.log.levels.INFO
      )

      -- Check if python parser is installed *once* before the loop
      -- local ts_parsers = require("vim.treesitter.parsers")
      -- if not ts_parsers.has_parser("python") then
      --   vim.notify("Python Treesitter parser not installed. Run :TSInstall python", vim.log.levels.ERROR)
      --   M.process_found_imports({}, undefined_names)
      --   return
      -- end

      for _, file_path in ipairs(python_files) do
        -- Skip the current file
        if vim.fn.expand("%:p") == vim.fn.fnamemodify(file_path, ":p") then
          goto continue_files
        end

        local relative_path = file_path:sub(#project_root + 2)
        local module_path = relative_path:gsub("/", "."):gsub("%.py$", "")
        if module_path:match("__init__$") then
          module_path = module_path:gsub(".__init__$", "")
        end

        -- Read file content
        local file_content_lines = vim.fn.readfile(file_path)
        if not file_content_lines then
          vim.notify("Could not read file: " .. file_path, vim.log.levels.WARN)
          goto continue_files
        end
        -- get the file content as a string

        local temp_bufnr = -1
        local root = nil
        local temp_parser = nil -- Declare parser outside pcall

        -- Use pcall for safety during buffer/parser operations
        local ok, result = pcall(function()
          -- 1. Create a temporary, unlisted, scratch buffer
          temp_bufnr = vim.api.nvim_create_buf(false, true)

          -- 2. Set the content of the temporary buffer
          vim.api.nvim_buf_set_lines(temp_bufnr, 0, -1, false, file_content_lines)

          -- 3. Get a parser specifically for this temporary buffer and language
          --    No need to set filetype, just request the 'python' parser for this bufnr
          temp_parser = vim.treesitter.get_parser(temp_bufnr, "python")
          if not temp_parser then
            error("Failed to get parser for temp buffer " .. temp_bufnr) -- Throw error to be caught by pcall
          end

          -- 4. Parse the temporary buffer's content
          --    parse() returns a table of trees (usually just one)
          local trees = temp_parser:parse(true)
          if not trees or not trees[1] then
            error("Failed to parse content of temp buffer " .. temp_bufnr) -- Throw error
          end

          -- 5. Get the root node of the first tree
          return trees[1]:root()
        end)

        if not ok then
          vim.notify("Error processing file " .. file_path .. ": " .. tostring(result), vim.log.levels.WARN)
          -- Clean up buffer if it was created
          if temp_bufnr ~= -1 and vim.api.nvim_buf_is_valid(temp_bufnr) then
            vim.api.nvim_buf_delete(temp_bufnr, { force = true })
          end
          goto continue_files
        end

        -- If pcall succeeded, 'result' is the root node
        root = result

        -- Define Treesitter queries
        local queries = {
          function_definition = "(function_definition name: (identifier) @name)",
          class_definition = "(class_definition name: (identifier) @name)",
        }

        for query_name, query_string in pairs(queries) do
          local success, query = pcall(vim.treesitter.query.parse, "python", query_string)
          if success and query then
            -- Iterate captures using the root node and the ORIGINAL file content lines
            for id, node, _ in query:iter_captures(root, file_content_lines, 0, -1) do
              if query.captures[id] == "name" then
                -- Pass ORIGINAL file content lines to get_node_text
                local node_text_list = vim.treesitter.get_node_text(node, table.concat(file_content_lines, "\n"), {})
                local defined_name = node_text_list

                -- Check if the defined name is in the undefined set
                if defined_name and defined_name ~= "" and undefined_set[defined_name] then
                  local import_path = module_path .. "." .. defined_name
                  local already_added = false
                  for _, existing_import in ipairs(possible_imports[defined_name]) do
                    if existing_import == import_path then
                      already_added = true
                      break
                    end
                  end
                  if not already_added then
                    table.insert(possible_imports[defined_name], import_path)
                  end
                end
              end
            end
          else
            vim.notify(
              "Could not parse Treesitter query: " .. query_name .. " - " .. (query or "Error"),
              vim.log.levels.WARN
            )
          end
        end

        -- Clean up the temporary buffer
        if temp_bufnr ~= -1 and vim.api.nvim_buf_is_valid(temp_bufnr) then
          vim.api.nvim_buf_delete(temp_bufnr, { force = true })
        end

        ::continue_files::
      end

      -- Filter out names with no found imports
      local resolvable_imports = {}
      for name, imports in pairs(possible_imports) do
        if #imports > 0 then
          resolvable_imports[name] = imports
        end
      end

      vim.notify("Treesitter search finished. Processing results...", vim.log.levels.INFO)
      M.process_found_imports(resolvable_imports, undefined_names)
    end,
  })

  return {} -- Return immediately, processing happens in callback
end

-- Function to process the imports found by ripgrep (made public for the callback)
function M.process_found_imports(resolvable_imports, undefined_names)
  if vim.tbl_isempty(resolvable_imports) then
    local not_found_names = {}
    local found_names_set = {}
    for name, _ in pairs(resolvable_imports) do
      found_names_set[name] = true
    end
    for _, name in ipairs(undefined_names) do
      if not found_names_set[name] then
        table.insert(not_found_names, name)
      end
    end

    if #not_found_names > 0 then
      vim.notify(
        "Could not find potential imports in the project for: " .. table.concat(not_found_names, ", "),
        vim.log.levels.INFO
      )
    else
      -- This case might occur if ripgrep found files but Treesitter found no matches
      vim.notify("Could not find matching definitions for the missing names.", vim.log.levels.INFO)
    end
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
      -- Handle cases where the module path might be empty (e.g., importing from top-level __init__.py)
      local module_path_str = #parts > 0 and table.concat(parts, ".") or ""

      if module_path_str ~= "" then
        table.insert(imports_to_add, "from " .. module_path_str .. " import " .. imported_name)
      else
        -- If module path is empty, it might be a direct import (less common for functions/classes)
        -- Or it implies importing the module itself if 'name' was the module.
        -- Adjust logic as needed. For now, assume 'from . import name' isn't the goal.
        -- Maybe just 'import name' if 'name' is a module found directly under root?
        -- Let's stick to 'from module import name' format for now.
        vim.notify("Skipping import for '" .. name .. "' with empty module path: " .. import_path, vim.log.levels.WARN)
      end
    else
      -- Multiple options, need user selection
      table.insert(ambiguous_imports, { name = name, imports = imports })
    end
  end

  -- Function to add import statements to the buffer
  -- TODO: debug text insertion location
  local function add_imports_to_buffer(imports_to_add)
    local bufnr = vim.api.nvim_get_current_buf()
    local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local existing_imports = {}
    for _, line in ipairs(current_lines) do
      if line:match("^%s*import%s+") or line:match("^%s*from%s+") then
        existing_imports[vim.trim(line)] = true
      end
    end

    local unique_imports_to_add = {}
    local added_count = 0
    for _, import_statement in ipairs(imports_to_add) do
      if not existing_imports[vim.trim(import_statement)] then
        table.insert(unique_imports_to_add, import_statement)
        existing_imports[vim.trim(import_statement)] = true -- Mark as added
        added_count = added_count + 1
      end
    end

    if added_count == 0 then
      vim.notify("All suggested imports already exist.", vim.log.levels.INFO)
      return
    end

    -- Find the line number after the last existing import statement
    -- Or 0 if no imports are found
    local insert_line = 0
    for i, line in ipairs(current_lines) do
      -- Basic check for import statements (can be improved)
      if line:match("^%s*import%s+") or line:match("^%s*from%s+") then
        insert_line = i
      end
    end

    -- Adjust insert_line to be 0-indexed for the API call
    local api_insert_line = math.max(0, insert_line)

    -- Prepare the lines to insert, potentially adding newlines for spacing
    local lines_to_insert = {}
    local needs_leading_newline = false
    local needs_trailing_newline = false

    -- Add newline before new imports if inserting after existing code/imports
    if api_insert_line > 0 then
      local line_before = current_lines[api_insert_line] -- Line *before* insertion point (1-based index)
      if line_before and vim.trim(line_before) ~= "" then
        needs_leading_newline = true
      end
    end

    -- Add newline after new imports if there's code immediately following
    if #current_lines > api_insert_line then
      local line_after = current_lines[api_insert_line + 1] -- Line *at* insertion point (1-based index)
      if
        line_after
        and vim.trim(line_after) ~= ""
        and not (line_after:match("^%s*import%s+") or line_after:match("^%s*from%s+"))
      then
        needs_trailing_newline = true
      end
    end

    if needs_leading_newline then
      table.insert(lines_to_insert, "")
    end
    for _, import_statement in ipairs(unique_imports_to_add) do
      table.insert(lines_to_insert, import_statement)
    end
    if needs_trailing_newline then
      table.insert(lines_to_insert, "")
    end

    -- Insert the lines into the buffer
    vim.api.nvim_buf_set_lines(bufnr, api_insert_line, api_insert_line, false, lines_to_insert)

    vim.notify("Added " .. added_count .. " new import statement(s).", vim.log.levels.INFO)
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
          return item -- Display the full import path
        end,
      }, function(selected_import_path)
        if selected_import_path then
          -- Construct the import statement: from module.path import name
          local parts = vim.split(selected_import_path, "%.")
          local imported_name = table.remove(parts) -- Get the last part (the name)
          local module_path_str = #parts > 0 and table.concat(parts, ".") or ""

          if module_path_str ~= "" then
            table.insert(imports_to_add, "from " .. module_path_str .. " import " .. imported_name)
          else
            vim.notify(
              "Skipping selected import for '" .. name .. "' with empty module path: " .. selected_import_path,
              vim.log.levels.WARN
            )
          end
        end
        -- Process the next ambiguous import recursively
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

  -- Start processing ambiguous imports if any, otherwise add directly
  if #ambiguous_imports > 0 then
    process_next_ambiguous()
  elseif #imports_to_add > 0 then
    add_imports_to_buffer(imports_to_add)
  else
    vim.notify("No valid imports found to add.", vim.log.levels.INFO)
  end
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
    vim.notify("No missing imports found based on diagnostics.", vim.log.levels.INFO)
    return
  end

  vim.notify("Found potential missing names: " .. table.concat(undefined_names, ", "), vim.log.levels.INFO)

  -- 2. Verify possible imports
  local project_root = find_project_root()
  if not project_root then
    vim.notify("Could not find project root (pyproject.toml).", vim.log.levels.WARN)
    return
  end
  -- find_possible_imports now triggers the next step asynchronously via its callback
  find_possible_imports(undefined_names, project_root)

  -- The rest of the logic is handled asynchronously in M.process_found_imports
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
