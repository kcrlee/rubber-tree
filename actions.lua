local M = {}

M.open = function()
	local tree = require("rubber.tree")

	-- Ensure cwd is set before using it
	if not tree.cwd then
		tree.cwd = vim.fn.getcwd() -- Default to the current working directory
	end

	local line = vim.api.nvim_get_current_line()
	local filepath = tree.cwd .. "/" .. line

	local is_dir = vim.fn.isdirectory(filepath) == 1

	if is_dir then
		tree.cwd = filepath
		require("rubber.tree").render_tree()
	else
		vim.cmd("edit " .. vim.fn.fnameescape(filepath))
	end
end

return M
