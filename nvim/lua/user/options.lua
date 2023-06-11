--tabs
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

--indent + wrap
vim.opt.smartindent = true
vim.opt.wrap = false

--line numbers
vim.opt.number = true
vim.opt.relativenumber = true

--completion
vim.opt.wildmode = 'longest:full,full' -- complete the longest common match, and allow tabbing the results

--title (filename + directory)
vim.opt.title = true

--enable mouse
vim.opt.mouse = 'a' --enable for all modes

--better colors
vim.opt.termguicolors = true

--spellcheck
vim.opt.spell = true

--search
vim.opt.ignorecase = true
vim.opt.smartcase = true --if there are capital letters, turn into case sensitive

--render tabs, trailing spaces and end of buffer as custom chars
vim.opt.list = true --enable the below listchars
vim.opt.listchars = { tab = '▸ ', trail = '·' }

--split by default below and right
vim.opt.splitbelow = true
vim.opt.splitright = true

--offset y and x on scroll
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

--clipboard
vim.opt.clipboard = 'unnamedplus' --use system clipboard

--exiting a file without saving
vim.opt.confirm = true -- ask for saving instead of erroring

--persist history across sessions
vim.opt.undofile = true --persist undo
vim.opt.backup = true --automatically save a backup of current file
vim.opt.backupdir:remove('.') --keep backups out of the current directory (will go in home directory in hidden file)
