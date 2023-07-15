-- emmet_ls
-- automatically setup emmet_ls
lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
  return server ~= "emmet_ls"
end, lvim.lsp.automatic_configuration.skipped_servers)

local emmet_opts = {
  -- cmd = { "emmet-ls", "--stdio" },
  filetypes = { "astro", "blade", "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact",
    "svelte", "vue" },
  on_init = require("lvim.lsp").common_on_init,
  capabilities = require("lvim.lsp").common_capabilities(),
}
require("lvim.lsp.manager").setup("emmet_ls", emmet_opts)

-- HTML
local html_opts = {
  filetypes = { "astro", "blade", "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact",
    "svelte", "vue" },
  on_init = require("lvim.lsp").common_on_init,
  capabilities = require("lvim.lsp").common_capabilities(),
}
require("lvim.lsp.manager").setup("html", html_opts)
