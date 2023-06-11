local db = require('dashboard')

local header = {
  '',
  '',
  '██████╗░███████╗███████╗███████╗',
  '██╔══██╗██╔════╝██╔════╝╚════██║',
  '██║░░██║█████╗░░█████╗░░░░███╔═╝',
  '██║░░██║██╔══╝░░██╔══╝░░██╔══╝░░',
  '██████╔╝███████╗███████╗███████╗',
  '╚═════╝░╚══════╝╚══════╝╚══════╝',
  '',
}

local footer = {
  '',
  '',
  '.🅽🆄🆃🆂.',
  '',
}

db.setup({
  theme = 'doom',
  config = {
    header = header, --your header
    center = {
      { icon = '  ', desc = 'New file                       ', action = 'enew' },
      { icon = '  ', shortcut = 'SPC f', desc = 'Find file                 ', action = 'Telescope find_files' },
      { icon = '  ', shortcut = 'SPC h', desc = 'Recent files              ', action = 'Telescope oldfiles' },
      { icon = '  ', shortcut = 'SPC g', desc = 'Find Word                 ', action = 'Telescope live_grep' },
    },
    footer = footer  --your footer
  }
})

vim.cmd([[
  augroup DashboardHighlights
    autocmd ColorScheme * highlight DashboardHeader guifg=#6272a4
    autocmd ColorScheme * highlight DashboardCenter guifg=#f8f8f2
    autocmd ColorScheme * highlight DashboardShortcut guifg=#bd93f9
    autocmd ColorScheme * highlight DashboardFooter guifg=#6272a4
  augroup end
]])
vim.api.nvim_set_hl(0, 'DashboardHeader', { fg = '#6272a4' })
vim.api.nvim_set_hl(0, 'DashboardCenter', { fg = '#f8f8f2' })
vim.api.nvim_set_hl(0, 'DashboardShortcut', { fg = '#bd93f9' })
vim.api.nvim_set_hl(0, 'DashboardFooter', { fg = '#6272a4' })
