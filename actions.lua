local M = {}

M.open = function()
	local line = vim.api.nvim_get_current_line()
	local filepath = require("myfiletree.tree").cwd .. "/" .. line

	local is_dir = vim.fn.isdirectory(filepath) == 1

	if is_dir then
		-- Change directory and refresh tree
		require("myfiletree.tree").cwd = filepath
		require("myfiletree.tree").render_tree()
	else
		-- Open file in the current window
		vim.cmd("edit " .. filepath)
	end
end

return M
