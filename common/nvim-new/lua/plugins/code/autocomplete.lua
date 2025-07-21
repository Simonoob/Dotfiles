local lua_snip = {
  -- Snippet Engine & its associated nvim-cmp source
  "L3MON4D3/LuaSnip",
  pin = true,
  build = (function()
    -- Build Step is needed for regex support in snippets.
    -- This step is not supported in many windows environments.
    -- Remove the below condition to re-enable on windows.
    if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
      return
    end
    return "make install_jsregexp"
  end)(),
  dependencies = {
    -- `friendly-snippets` contains a variety of premade snippets.
    --    See the README about individual language/framework/plugin snippets:
    --    https://github.com/rafamadriz/friendly-snippets
    {
      "rafamadriz/friendly-snippets",
      pin = true,
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_lua").load({ paths = { "~/.config/nvim/lua/plugins/code/snippets/" } })
      end,
    },
  },
  opts = {
    history = true,
    delete_check_events = "TextChanged",
    update_events = "TextChanged,TextChangedI",
  },
}

return {
  "hrsh7th/nvim-cmp",
  pin = true,
  dependencies = {
    lua_snip,
    { "saadparwaiz1/cmp_luasnip", pin = true },

    -- Adds other completion capabilities.
    --  nvim-cmp does not ship with all sources by default. They are split
    --  into multiple repos for maintenance purposes.
    { "hrsh7th/cmp-nvim-lsp", pin = true },
    { "hrsh7th/cmp-buffer", pin = true },
    { "hrsh7th/cmp-path", pin = true },
    { "hrsh7th/cmp-nvim-lsp-signature-help", pin = true },
  },

  config = function()
    -- See `:help cmp`
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    luasnip.config.setup({})

    cmp.setup.cmdline(":", {
      enabled = false,
    })
    cmp.setup.cmdline("/", {
      enabled = false,
    })

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      completion = { completeopt = "menu,menuone,noinsert" },

      -- For an understanding of why these mappings were
      -- chosen, you will need to read `:help ins-completion`
      --
      -- No, but seriously. Please read `:help ins-completion`, it is really good!
      mapping = cmp.mapping.preset.insert({
        -- Navigate between snippet placeholder
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-u>"] = cmp.mapping.scroll_docs(4),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<S-CR>"] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        }),
        ["<C-CR>"] = function(fallback)
          cmp.abort()
          fallback()
        end,
        -- Use Tab for completion confirmation and snippet navigation
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm({ select = true })
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
        -- Navigate between completion items
        ["<C-j>"] = cmp.mapping.select_next_item(),
        ["<C-k>"] = cmp.mapping.select_prev_item(),

        -- Manually trigger a completion from nvim-cmp.
        --  Generally you don't need this, because nvim-cmp will display
        --  completions whenever it has completion options available.
        ["<C-Space>"] = cmp.mapping.complete({}),
      }),
      sources = {
        {
          name = "lazydev",
          -- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
          group_index = 0,
        },
        { name = "nvim_lsp", group_index = 1 },
        { name = "luasnip", group_index = 2 },
        -- { name = "copilot", group_index = 3 }, I want to try triggering copilot manually for a while
        { name = "nvim_lsp_signature_help", group_index = 4 },
        { name = "path", group_index = 6 },
        { name = "buffer", group_index = 7 },
      },
      experimental = {
        ghost_text = {
          hl_group = "BlinkCmpGhostText",
        },
      },
    })
  end,
}
