--MAPPINGS FOR BASE NVIM
--set leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

--when text is wrapped, move by terminal rows, not lines, unless a count is provided
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

--reselect visual selection after indenting
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

--maintain cursor position after yanking a visual selection
--http://ddrscott.github.io/blog/2016/yank-without-jank/
vim.keymap.set('v', 'y', 'myy`y')
vim.keymap.set('v', 'Y', 'myY`y')

--paste replace visual selection without copying it
vim.keymap.set('v', 'p', '"_dP')

--easy insertion of a trailing ; or , from insert mode
vim.keymap.set('i', ';;' , '<Esc>A;')
vim.keymap.set('i', ',,' , '<Esc>A,')

--clear search highlights
vim.keymap.set('n', '<Leader>h', ':nohlsearch<CR>')

--open the current file in the default program (on Mac this should just be just `open`)
vim.keymap.set('n', '<leader>x', ':!open %<cr><cr>')

-- Move text up and down [TO BE CHANGED TO WORK ON MAC]
--vim.keymap.set('i', '<A-j>', '<Esc>:move .+1<CR>==gi')
--vim.keymap.set('i', '<A-k>', '<Esc>:move .-2<CR>==gi')
--vim.keymap.set('x', '<A-j>', ":move '>+1<CR>gv-gv")
--vim.keymap.set('x', '<A-k>', ":move '<-2<CR>gv-gv")
