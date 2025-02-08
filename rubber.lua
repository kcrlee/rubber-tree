local renderer = require("rubber.renderer")

local M = {}

M.tree_buf = nil
M.cwd = vim.fn.getcwd()

-- Open the file tree in a buffer
M.open = function()
	if M.tree_buf and vim.api.nvim_buf_is_valid(M.tree_buf) then
		vim.api.nvim_set_current_buf(M.tree_buf)
		return
	end

	-- Create a new buffer
	M.tree_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(M.tree_buf, "file-tree")
	vim.api.nvim_buf_set_option(M.tree_buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(M.tree_buf, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(M.tree_buf, "modifiable", true)

	-- Open the buffer in the current window
	vim.api.nvim_set_current_buf(M.tree_buf)

	-- Render initial file tree
	renderer.render_tree(M.tree_buf, M.cwd)

	-- Set up buffer-local keymaps
	require("rubber.keymaps").setup(M.tree_buf)

	-- Detect save (`:w`) to sync changes
	vim.api.nvim_create_autocmd("BufWritePost", {
		buffer = M.tree_buf,
		callback = function()
			renderer.sync_changes(M.tree_buf, M.cwd)
		end,
	})
end

return M
