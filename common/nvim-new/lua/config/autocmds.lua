-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- < map CapsLock to Esc key when within neovim >
-- IMPORTANT: this is macOS specific - actually on my macOS I used the builtin `customise modifier keys` from the options, otherwise I would get conflics when switching to the terminal from within neovim
--
-- local function remapCapsLockToEscape()
-- 	os.execute(
-- 		'hidutil property --set \'{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}\''
-- 	)
-- end
--
-- local function unmapCapsLockToEscape()
-- 	os.execute(
-- 		'hidutil property --set \'{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000029,"HIDKeyboardModifierMappingDst":0x700000039}]}\''
-- 	)
-- end
--
-- vim.api.nvim_create_autocmd("VimEnter", {
-- 	callback = remapCapsLockToEscape,
-- })
--
-- vim.api.nvim_create_autocmd("VimLeave", {
-- 	callback = unmapCapsLockToEscape,
-- })
-- </ map CapsLock to Esc key when within neovim >
