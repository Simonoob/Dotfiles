-- utils module
---@class MissingImports.Utils
local M = {}

M.debug = false

---helper function for conditional logging
---@param msg string
---@param level vim.log.levels
M.log = function(msg, level)
  vim.notify("[python_imports] " .. msg, level or vim.log.levels.DEBUG)
end

---get diagnostics for unresolved imports in current buffer
---@return vim.Diagnostic[]
M.get_unresolved_imports_diagnostics = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local diagnostics = vim.diagnostic.get(bufnr)

  local filtered_diagnostics = {}
  for _, diagnostic in ipairs(diagnostics) do
    if M.is_unresolved_import_diagnostic(diagnostic) then
      table.insert(filtered_diagnostics, diagnostic)
    end
  end
  return filtered_diagnostics
end

---@param diagnostic vim.Diagnostic
---@return boolean
M.is_unresolved_import_diagnostic = function(diagnostic)
  return diagnostic.severity == vim.diagnostic.severity.ERROR and diagnostic.code == "reportUndefinedVariable" -- this name is Pyright specific
end

M.lsp_response_result_to_completion_items = function(result, prefix)
  if vim.fn.has("nvim-0.11.0") == 1 then
    return vim.lsp.completion._lsp_to_complete_items(result, prefix)
  elseif vim.fn.has("nvim-0.10.0") == 1 then
    return vim.lsp.util.text_document_completion_list_to_complete_items(result, prefix)
  else
    return require("vim.lsp.util").text_document_completion_list_to_complete_items(result, prefix)
  end
end

---@param lsp_response_result lsp.CompletionList|lsp.CompletionItem[] from `textDocument/completion`
---@param unresolved_import_name string|nil
---@return table[]
M.get_auto_import_completion_items = function(lsp_response_result, unresolved_import_name)
  local completion_items = M.lsp_response_result_to_completion_items(lsp_response_result, unresolved_import_name)

  if vim.tbl_isempty(completion_items) then
    M.log('no completion results found for "' .. unresolved_import_name .. '"', vim.log.levels.DEBUG)
    return {}
  end

  return vim.tbl_filter(function(completion_item)
    local completion_item_description, completion_item_edits =
      completion_item.user_data
        and completion_item.user_data.nvim
        and completion_item.user_data.nvim.lsp
        and completion_item.user_data.nvim.lsp.completion_item
        and completion_item.user_data.nvim.lsp.completion_item.labelDetails
        and completion_item.user_data.nvim.lsp.completion_item.labelDetails.description,
      completion_item.user_data.nvim.lsp.completion_item.additionalTextEdits

    return completion_item.word == unresolved_import_name
      and completion_item_description
      and completion_item_edits
      and not vim.tbl_isempty(completion_item_edits)
      and completion_item.menu == "Auto-import"
  end, completion_items)
end

---handle the async response from the LSP for `textDocument/completion`
---@param error lsp.ResponseError
---@param response_result any
---@param diagnostic vim.Diagnostic
M.handle_lsp_import_response = function(error, response_result, diagnostic)
  local unresolved_import_name = M.get_unresolved_import_name(diagnostic)
  if error then
    M.log(
      string.format("LSP error when processing `%s`: ", unresolved_import_name) .. vim.inspect(error),
      vim.log.levels.ERROR
    )
    return
  end

  if not response_result or vim.tbl_isempty(response_result.items) then
    M.log("no import found for " .. unresolved_import_name, vim.log.levels.INFO)
    return
  end

  local auto_imports_completions = M.get_auto_import_completion_items(response_result, unresolved_import_name)

  if #auto_imports_completions == 1 then
    M.resolve_import_from_lsp(auto_imports_completions[1], diagnostic.bufnr)
  else
    print('multiple auto-imports found for "' .. unresolved_import_name .. '"')
  end
end

---add import statement to buffer from LSP completion item
---@param auto_import_from_lsp any|nil
---@param bufnr any
M.resolve_import_from_lsp = function(auto_import_from_lsp, bufnr)
  if auto_import_from_lsp == nil then
    M.log("no auto import found", vim.log.levels.DEBUG)
    return
  end

  vim.lsp.util.apply_text_edits(
    auto_import_from_lsp.user_data.nvim.lsp.completion_item.additionalTextEdits,
    bufnr,
    "utf-8"
  )
end

---get the name of the unresolved import from the diagnostic (e.g. variable name)
---@param diagnostic vim.Diagnostic
---@return string|nil
M.get_unresolved_import_name = function(diagnostic)
  if not (diagnostic.severity == vim.diagnostic.severity.ERROR and M.is_unresolved_import_diagnostic(diagnostic)) then
    M.log("diagnostic is not an unresolved import: " .. vim.inspect(diagnostic), vim.log.levels.DEBUG)
    return
  end

  local text = vim.api.nvim_buf_get_text(
    diagnostic.bufnr,
    diagnostic.lnum,
    diagnostic.col,
    diagnostic.end_lnum,
    diagnostic.end_col,
    {}
  )[1]

  return text
end

return M
