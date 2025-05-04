-- lua/missing_imports/init.lua

local M = {}

-- Configuration table, initialized with defaults
local config = {
  debug = false, -- Default debug flag
}

local utils = require("config.cmds.python_imports.utils")
utils.debug = config.debug

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
      utils.notify_debug("Could not find potential imports in the project for: " .. table.concat(not_found_names, ", "))
    else
      utils.notify_debug("Could not find matching definitions for the missing names.")
    end
    return
  end

  utils.notify_debug("Found possible imports for: " .. table.concat(vim.tbl_keys(resolvable_imports), ", "))

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
        utils.notify_debug(
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
            utils.notify_debug(
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
        utils.add_imports_to_buffer(imports_to_add)
      else
        utils.notify_debug("No imports selected or automatically resolved.")
      end
    end
  end

  -- Start processing
  if #ambiguous_imports > 0 then
    process_next_ambiguous()
  elseif #imports_to_add > 0 then
    utils.add_imports_to_buffer(imports_to_add)
  else
    utils.notify_debug("No valid imports found to add.")
  end
end

-- Main function
function M.add_missing_imports()
  if vim.bo.filetype ~= "python" then
    -- Keep filetype check unconditional? Yes.
    vim.notify("MissingImports only works in Python files.", vim.log.levels.INFO)
    return
  end
  utils.notify_debug("Scanning for missing imports...")

  local diagnostics = utils.get_diagnostics()
  local undefined_names = utils.identify_undefined_names(diagnostics)

  if #undefined_names == 0 then
    utils.notify_debug("No missing imports found based on diagnostics.")
    return
  end
  utils.notify_debug("Found potential missing names: " .. table.concat(undefined_names, ", "))

  local project_root = utils.find_project_root()
  if not project_root then
    -- Keep project root error unconditional
    vim.notify("Could not find project root (pyproject.toml).", vim.log.levels.WARN)
    return
  end

  utils.find_possible_imports(undefined_names, project_root, M.process_found_imports)
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

  utils.notify_debug("MissingImports setup complete.") -- Make setup message debug only
end

return M
