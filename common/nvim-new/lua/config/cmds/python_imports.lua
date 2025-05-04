-- lua/missing_imports/init.lua

local M = {}

-- Configuration table, initialized with defaults
local config = {
  debug = false, -- Default debug flag
}

-- Helper function for conditional logging
local function notify_debug(msg, level)
  if config.debug then
    vim.notify(msg, level or vim.log.levels.INFO)
  end
end

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
  local diagnostics = vim.diagnostic.get(bufnr)
  return diagnostics or {}
end

-- Function to identify undefined names from diagnostics using code and range
local function identify_undefined_names(diagnostics)
  local undefined_names = {}
  local bufnr = vim.api.nvim_get_current_buf()

  for _, diag in ipairs(diagnostics) do
    if diag.severity == vim.diagnostic.severity.ERROR and diag.code then
      -- Check for specific diagnostic codes that indicate an undefined variable.
      -- The exact code might vary depending on the LSP server (e.g., Pyright, pylsp).
      -- 'reportUndefinedVariable' is a common one for Pyright.
      if diag.code == "reportUndefinedVariable" or diag.code == "undefined-variable" then
        -- Use the diagnostic range to get the exact text of the undefined name
        local start_row = diag.lnum -- lnum is 0-indexed line
        local start_col = diag.col -- col is 0-indexed character
        local end_row = diag.end_lnum -- end_lnum is 0-indexed line
        local end_col = diag.end_col -- end_col is 0-indexed character

        -- nvim_buf_get_text expects 0-indexed start/end row/col
        local name_text = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})

        local name = table.concat(name_text, "\n") -- Join without newline for single identifier - this is probably not

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
        notify_debug("Ripgrep exited with code: " .. exit_code, vim.log.levels.WARN)
      end
      if #python_files == 0 then
        notify_debug("No Python files found in the project using ripgrep.")
        M.process_found_imports({}, undefined_names)
        return
      end

      local undefined_set = {}
      for _, undefined_name in ipairs(undefined_names) do
        undefined_set[undefined_name] = true
        possible_imports[undefined_name] = {}
      end

      notify_debug("Searching " .. #python_files .. " Python files for definitions using Treesitter...")

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
          notify_debug("Could not read file: " .. file_path, vim.log.levels.WARN)
          goto continue_files
        end

        local temp_bufnr = -1
        local root = nil
        local temp_parser = nil

        -- Use pcall for safety during buffer/parser operations
        local ok, result = pcall(function()
          temp_bufnr = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_lines(temp_bufnr, 0, -1, false, file_content_lines)
          temp_parser = vim.treesitter.get_parser(temp_bufnr, "python")
          if not temp_parser then
            error("Failed to get parser for temp buffer " .. temp_bufnr)
          end
          local trees = temp_parser:parse() -- Parse the entire buffer
          if not trees or not trees[1] then
            error("Failed to parse content of temp buffer " .. temp_bufnr)
          end
          return trees[1]:root()
        end)

        if not ok then
          -- Keep errors unconditional
          vim.notify("Error processing file " .. file_path .. ": " .. tostring(result), vim.log.levels.WARN)
          if temp_bufnr ~= -1 and vim.api.nvim_buf_is_valid(temp_bufnr) then
            vim.api.nvim_buf_delete(temp_bufnr, { force = true })
          end
          goto continue_files
        end
        root = result

        -- Define Treesitter queries
        local queries = {
          function_definition = "(function_definition name: (identifier) @name)",
          class_definition = "(class_definition name: (identifier) @name)",
        }

        for query_name, query_string in pairs(queries) do
          local success, query = pcall(vim.treesitter.query.parse, "python", query_string)
          if success and query then
            -- Iterate captures using the root node and the file content lines
            for id, node, _ in query:iter_captures(root, file_content_lines, 0, -1) do
              if query.captures[id] == "name" then
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

      notify_debug("Treesitter search finished. Processing results...")
      M.process_found_imports(resolvable_imports, undefined_names)
    end,
  })

  return {} -- Return immediately, processing happens in callback
end

-- Function to add import statements to the buffer using Treesitter for insertion point
local function add_imports_to_buffer(imports_to_add)
  local bufnr = vim.api.nvim_get_current_buf()
  local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- 1. Check for existing imports to avoid duplicates
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
      existing_imports[vim.trim(import_statement)] = true
      added_count = added_count + 1
    end
  end

  if added_count == 0 then
    notify_debug("All suggested imports already exist.")
    return
  end

  table.sort(unique_imports_to_add)
  local lines_to_insert = {}
  for _, import_statement in ipairs(unique_imports_to_add) do
    table.insert(lines_to_insert, import_statement)
  end

  -- 4. Insert the lines
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines_to_insert)

  -- Keep this notification unconditional
  vim.notify("Added " .. added_count .. " new import statement(s).", vim.log.levels.INFO)
end

-- Function to process the imports found by ripgrep
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
      notify_debug("Could not find potential imports in the project for: " .. table.concat(not_found_names, ", "))
    else
      notify_debug("Could not find matching definitions for the missing names.")
    end
    return
  end

  notify_debug("Found possible imports for: " .. table.concat(vim.tbl_keys(resolvable_imports), ", "))

  local imports_to_add = {}
  local ambiguous_imports = {}

  for name, imports in pairs(resolvable_imports) do
    if #imports == 1 then
      local import_path = imports[1]
      local parts = vim.split(import_path, "%.")
      local imported_name = table.remove(parts)
      local module_path_str = #parts > 0 and table.concat(parts, ".") or ""

      if module_path_str ~= "" then
        table.insert(imports_to_add, "from " .. module_path_str .. " import " .. imported_name)
      else
        notify_debug(
          "Skipping import for '" .. name .. "' with empty module path: " .. import_path,
          vim.log.levels.WARN
        )
      end
    else
      table.insert(ambiguous_imports, { name = name, imports = imports })
    end
  end

  -- Process ambiguous imports sequentially
  local function process_next_ambiguous()
    if #ambiguous_imports > 0 then
      local current_ambiguous = table.remove(ambiguous_imports, 1)
      local name = current_ambiguous.name
      local imports = current_ambiguous.imports

      vim.ui.select(imports, {
        prompt = "Select import for '" .. name .. "':",
      }, function(selected_import_path)
        if selected_import_path then
          local import_parts = vim.split(selected_import_path, "%.")
          local imported_name = table.remove(import_parts) -- pop the last part (the imported item name)
          local module_path_str = #import_parts > 0 and table.concat(import_parts, ".") or ""

          if module_path_str ~= "" then
            table.insert(imports_to_add, "from " .. module_path_str .. " import " .. imported_name)
          else
            notify_debug(
              "Skipping selected import for '" .. name .. "' with empty module path: " .. selected_import_path,
              vim.log.levels.WARN
            )
          end
        end
        process_next_ambiguous()
      end)
    else
      -- All ambiguous imports processed
      if #imports_to_add > 0 then
        add_imports_to_buffer(imports_to_add)
      else
        notify_debug("No imports selected or automatically resolved.")
      end
    end
  end

  -- Start processing
  if #ambiguous_imports > 0 then
    process_next_ambiguous()
  elseif #imports_to_add > 0 then
    add_imports_to_buffer(imports_to_add)
  else
    notify_debug("No valid imports found to add.")
  end
end

-- Main function
function M.add_missing_imports()
  if vim.bo.filetype ~= "python" then
    -- Keep filetype check unconditional? Yes.
    vim.notify("MissingImports only works in Python files.", vim.log.levels.INFO)
    return
  end
  notify_debug("Scanning for missing imports...")

  local diagnostics = get_diagnostics()
  local undefined_names = identify_undefined_names(diagnostics)

  if #undefined_names == 0 then
    notify_debug("No missing imports found based on diagnostics.")
    return
  end
  notify_debug("Found potential missing names: " .. table.concat(undefined_names, ", "))

  local project_root = find_project_root()
  if not project_root then
    -- Keep project root error unconditional
    vim.notify("Could not find project root (pyproject.toml).", vim.log.levels.WARN)
    return
  end

  find_possible_imports(undefined_names, project_root)
end

--- Setup function for the plugin
-- Accepts an 'opts' table, uses 'debug' key.
function M.setup(opts)
  opts = opts or {}
  -- Merge user options with defaults
  config = vim.tbl_deep_extend("force", config, opts)

  vim.api.nvim_create_user_command("MissingImports", M.add_missing_imports, {
    desc = "Find and add missing Python imports based on LSP diagnostics",
    nargs = 0,
  })

  notify_debug("MissingImports setup complete.") -- Make setup message debug only
end

return M
