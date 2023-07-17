-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Package manager
require("packageManager")

require("options")

require("generalKeymaps")

require("generalSettings")

require("telescopeSetup")

require("treesitterSetup")

require("lspSetup")

require("autoCompleteSetup")
-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
