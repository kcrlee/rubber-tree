-- local keymaps = require("rubber.keymaps") -- ✅ Ensure this returns a table
--
-- local M = {}
--
-- M.tree_buf = nil
-- M.cwd = M.cwd or vim.fn.getcwd()
--
-- M.open = function()
-- 	if not M.tree_buf then
-- 		M.tree_buf = vim.api.nvim_create_buf(false, true)
-- 		vim.api.nvim_buf_set_name(M.tree_buf, "file-tree")
-- 		vim.api.nvim_buf_set_option(M.tree_buf, "buftype", "nofile")
-- 		vim.api.nvim_buf_set_option(M.tree_buf, "bufhidden", "hide")
-- 		vim.api.nvim_buf_set_option(M.tree_buf, "modifiable", true)
-- 	end
--
-- 	-- Open in the current window
-- 	vim.api.nvim_set_current_buf(M.tree_buf)
--
-- 	-- Setup buffer-local keymaps
-- 	keymaps.setup(M.tree_buf) -- ✅ Ensure this is a function
-- end
--
-- return M

local renderer = require("rubber.renderer")

local M = {}

M.tree_buf = nil
M.cwd = vim.fn.getcwd()

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

	-- Open in a split
	vim.cmd("vsplit")
	vim.api.nvim_set_current_buf(M.tree_buf)

	-- Render the file tree
	renderer.render_tree(M.tree_buf, M.cwd)
end

return M
