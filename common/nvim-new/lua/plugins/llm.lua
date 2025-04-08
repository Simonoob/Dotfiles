return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		strategies = {
			-- Change the default chat adapter
			chat = {
				adapter = "llama3",
			},
			inline = {
				adapter = "llama3",
			},
		},
		adapters = {
			llama3 = function()
				return require("codecompanion.adapters").extend("ollama", {
					name = "llama3", -- Differentiate from default ollama adapter
					schema = {
						model = {
							default = "llama3.2:latest",
						},
						num_ctx = {
							default = 16384,
						},
						num_predict = {
							default = -1,
						},
					},
				})
			end,
		},
		log_level = "DEBUG",
	},
}
