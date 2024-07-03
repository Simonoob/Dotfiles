-- Adds git related signs to the gutter, as well as utilities for managing changes
-- NOTE: gitsigns is already included in init.lua but contains only the base
-- config. This will add also the recommended keymaps.

return {
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
        virt_text_priority = 100,
      },

      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', '<leader>gj', function()
          if vim.wo.diff then
            vim.cmd.normal { 'gj', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = '[J] next hunk' })

        map('n', '<leader>gk', function()
          if vim.wo.diff then
            vim.cmd.normal { 'gk', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = '[K] previous hunk' })

        -- Actions
        -- visual mode
        map('v', '<leader>ghs', function()
          gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = '[S]tage hunk' })
        map('v', '<leader>ghr', function()
          gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = '[R]eset hunk' })
        -- normal mode
        map('n', '<leader>ghs', gitsigns.stage_hunk, { desc = '[S]tage hunk' })
        map('n', '<leader>ghr', gitsigns.reset_hunk, { desc = '[R]eset hunk' })
        map('n', '<leader>ghu', gitsigns.undo_stage_hunk, { desc = '[U]ndo staged hunk' })
        map('n', '<leader>ghp', gitsigns.preview_hunk, { desc = '[P]review hunk' })
        map('n', '<leader>gbs', gitsigns.stage_buffer, { desc = '[S]tage buffer' })
        map('n', '<leader>gbr', gitsigns.reset_buffer, { desc = '[R]eset buffer' })
        map('n', '<leader>gb', gitsigns.blame_line, { desc = '[B]lame line' })
        map('n', '<leader>gdi', gitsigns.diffthis, { desc = '[D]iff against [I]ndex' })
        map('n', '<leader>gdc', function()
          gitsigns.diffthis '@'
        end, { desc = '[D]iff against last [C]ommit' })
        -- Toggles
        map('n', '<leader>gtb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
        map('n', '<leader>gtd', gitsigns.toggle_deleted, { desc = '[T]oggle git show [D]eleted' })
      end,
    },
  },
}
