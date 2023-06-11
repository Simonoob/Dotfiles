-- Install packer
local ensure_packer = function ()
    local fn = vim.fn
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

-- Initialize packer
require('packer').reset()
require('packer').init({
  compile_path = vim.fn.stdpath('data')..'/site/plugin/packer_compiled.lua',
 display = {
   open_fn = function()
     return require('packer.util').float({ border = 'solid' })
   end,
 },
})

-- Install plugins
local use = require('packer').use

-- color theme
use({
    'jessarcher/onedark.nvim',
    config = function()
      vim.cmd('colorscheme onedark')

      -- Hide the characters in FloatBorder
      vim.api.nvim_set_hl(0, 'FloatBorder', {
          fg = vim.api.nvim_get_hl_by_name('NormalFloat', true).background,
          bg = vim.api.nvim_get_hl_by_name('NormalFloat', true).background,
        })

      -- Hide the characters in CursorLineBg
      vim.api.nvim_set_hl(0, 'CursorLineBg', {
          fg = vim.api.nvim_get_hl_by_name('CursorLine', true).background,
          bg = vim.api.nvim_get_hl_by_name('CursorLine', true).background,
        })

      -- indent marks on file tree 
      vim.api.nvim_set_hl(0, 'NvimTreeIndentMarker', { fg = '#30323E' })

      -- Make the StatusLineNonText background the same as StatusLine
      vim.api.nvim_set_hl(0, 'StatusLineNonText', {
          fg = vim.api.nvim_get_hl_by_name('NonText', true).foreground,
          bg = vim.api.nvim_get_hl_by_name('StatusLine', true).background,
        })
    end,
  })

use('wbthomason/packer.nvim') -- Let packer manage itself

use("tpope/vim-commentary") -- comment support

use('tpope/vim-surround') -- delete/change surrounding tags

-- use("tpope/vim-eunuch") -- add commands like :Rename and :SudoWrite

-- use("tpope/vim-unimpaired") -- pairs of bracket mappings like [b and ]b

use("tpope/vim-sleuth") -- indent autodetection with editorconfig support

use("tpope/vim-repeat") -- allow to repeat plugins commands

use("sheerun/vim-polyglot") -- add more language definitions

use("farmergreg/vim-lastplace") -- jump to the last location when opening a file

use("nelstrom/vim-visual-star-search") -- enable searching selected text with *

use("jessarcher/vim-heritage") -- automatically create parent dirs when saving file

use({ "whatyouhide/vim-textobj-xmlattr",
    requires = 'kana/vim-textobj-user',
  }) -- add text objects for HTML attributes ==> "v x" to select an attribute

use({
    "airblade/vim-rooter",
    setup = function()
      -- instead of running every time we open a file, run when vim starts
      vim.g.rooter_manual_only = 1
    end,
    config = function()
      vim.cmd('Rooter')
    end,
  }) -- automatically set working directory to current project root

use({
    "windwp/nvim-autopairs",
    config = function()
      require('nvim-autopairs').setup()
    end,
  }) -- automatically add closing brackets, quotes etc.

use({
    "karb94/neoscroll.nvim",
    config = function()
      require('neoscroll').setup()
    end,
  }) -- add smooth scrolling

use({
    "AndrewRadev/splitjoin.vim",
    config = function()
      vim.g.splitjoin_trailing_comma = 1
      vim.g.splitjoin_php_method_chain_full = 1
    end,
  }) -- split/join objects/arrays/functions etc. on multiple lines => g S split - g J join

-- fuzzy find with telescope
use({
  'nvim-telescope/telescope.nvim',
  requires = {
    { 'nvim-lua/plenary.nvim' },
    { 'kyazdani42/nvim-web-devicons' },
    { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
    { 'nvim-telescope/telescope-live-grep-args.nvim' },
  },
  config = function()
    require('user/plugins/telescope')
  end,
})

-- file tree
use({
  'kyazdani42/nvim-tree.lua',
  requires = 'kyazdani42/nvim-web-devicons',
  config = function()
    require('user/plugins/nvim-tree')
  end,
})
-- status line
use({
  'nvim-lualine/lualine.nvim',
  requires = 'kyazdani42/nvim-web-devicons',
  config = function()
    require('user/plugins/lualine')
  end,
})

-- show buffers as tabs on top of the screen
use({
  'akinsho/bufferline.nvim',
  requires = 'kyazdani42/nvim-web-devicons',
  after = 'onedark.nvim',
  config = function()
    require('user/plugins/bufferline')
  end,
})

-- display indent lines
use({
  'lukas-reineke/indent-blankline.nvim',
  config = function()
    require('user/plugins/indent-blankline')
  end,
})

use {
  'glepnir/dashboard-nvim',
  event = 'VimEnter',
  config = function()
    require('user/plugins/dashboard')
  end,
  requires = {'nvim-tree/nvim-web-devicons'}
}

-- git integration
use({
  'lewis6991/gitsigns.nvim',
  requires = 'nvim-lua/plenary.nvim',
  config = function()
    require('gitsigns').setup({
        current_line_blame = true,
        sign_priority = 20,
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end
          -- keymaps
          map('n', '<leader>gh', function()
            if vim.wo.diff then return '<leader>gh' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, {expr=true})

          map('n', '<leader>gH', function()
            if vim.wo.diff then return '<leader>gH' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, {expr=true})

        end,
      })
  end,
})

use({
    'tpope/vim-fugitive',
    requires = 'tpope/vim-rhubarb',
  })

use({
  'voldikss/vim-floaterm',
})



-- Automatically set up your configuration after cloning packer.nvim
-- Put this at the end after all plugins
if packer_bootstrap then
    require('packer').sync()
end

vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile>
  augroup end
]])
