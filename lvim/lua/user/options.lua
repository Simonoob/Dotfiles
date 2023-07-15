-- GENERAL SETTINGS
vim.opt.relativenumber = true
vim.opt.timeoutlen = 350 -- control WhichKey timeout
vim.opt.scrolloff = 5    -- start scrolling 5 lines before edge of view
vim.opt.textwidth = 80   -- wrap lines at 80 characters
-- highlight any text on the line over 80 characters only on buffers
-- vim.cmd([[match ErrorMsg '\%>80v.\+']])

-- manual lsp servers installation
lvim.lsp.automatic_servers_installation = false
