-- read blade files as html
-- vim.cmd [[ autocmd BufNewFile,BufRead *.blade.php setlocal ft=html ]]
-- highlight any text on the line over 80 characters only on buffers
vim.cmd([[match WarningMsg '\%>80v.\+']])
