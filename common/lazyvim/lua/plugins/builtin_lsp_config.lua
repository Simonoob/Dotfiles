return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      phpactor = {
        filetypes = { "php", "blade" },
        settings = {
          phpactor = {
            filetypes = { "php", "blade" },
            files = {
              associations = { "*.php", "*.blade.php" }, -- Associating .blade.php files as well
              maxSize = 5000000,
            },
          },
        },
      },
    },
    setup = {
      vtsls = function(_, opts)
        opts.settings.vtsls.experimental.maxInlayHintLength = 30
      end,
    },
  },
}
