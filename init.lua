local M = {}

M.setup = function()
	if not M.cwd then
		M.cwd = vim.fn.getcwd() -- Ensure cwd is set when opening
	end

	-- Ensure the rest of the function works
	print("Current directory: " .. M.cwd) -- Debugging
end

return M
