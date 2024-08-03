return {
  "neovim/nvim-lspconfig",
  opts = {
    setup = {
      vtsls = function(_, opts)
        opts.settings.vtsls.experimental.maxInlayHintLength = 30
      end,
    },
  },
}
