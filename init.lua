local rubber = require("rubber.tree")

local M = {}

M.setup = function(opts)
	opts = opts or {}
	rubber.setup(opts)

	vim.api.nvim_create_user_command("RubberTreeToggle", rubber.toggle, {})
end

return M
