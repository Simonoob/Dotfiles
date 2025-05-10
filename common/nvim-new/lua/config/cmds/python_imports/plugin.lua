-- lua/missing_imports/init.lua

---@class MissingImports
---@field add_missing_imports fun()
local M = {}

-- Configuration table, initialized with defaults
local config = {}

local utils = require("config.cmds.python_imports.utils")

M.add_missing_imports = function()
  local diagnostics = utils.get_unresolved_imports_diagnostics()

  for _, diagnostic in ipairs(diagnostics) do
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(diagnostic.bufnr),
      position = { line = diagnostic.lnum, character = diagnostic.end_col },
    }

    vim.lsp.buf_request(diagnostic.bufnr, "textDocument/completion", params, function(err, result)
      utils.handle_lsp_import_response(err, result, diagnostic)
    end)
  end
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

  utils.log("setup completed", vim.log.levels.DEBUG)
end

return M
