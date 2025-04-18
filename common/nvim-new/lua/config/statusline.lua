local M = {}

-- Modified status component
function M.modified()
  return vim.bo.modified and "●" or ""
end

-- List of components to add to the statusline
M.components = {
  "%f", -- filename -tail
  "%=", -- split the following items to the right
  M.modified, -- is file modified?
  require("config.cmds.branch_review").get_statusline_indicator,
}

-- Function to build the statusline from the components list
function M.build_statusline()
  local statusline = ""
  for _, component in ipairs(M.components) do
    if type(component) == "string" then
      statusline = statusline .. " " .. component
    else
      statusline = statusline .. " " .. component()
    end
  end
  return statusline
end

-- Set the statusline to use the dynamic list of components
vim.o.statusline = "%{%v:lua.require'config.statusline'.build_statusline()%}"

return M
