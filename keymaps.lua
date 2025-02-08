local M = {}

M.setup = function(buf)
	local opts = { noremap = true, silent = true, buffer = buf }

	-- `-` to toggle file tree
	vim.api.nvim_set_keymap("n", "-", ":lua require('rubber.tree').open()<CR>", opts)

	-- `Enter` to open file or expand/collapse directory
	vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", ":lua require('rubber.actions').open()<CR>", opts)

	-- `i` to enter insert mode (like standard Vim behavior)
	vim.api.nvim_buf_set_keymap(buf, "n", "i", "i", opts)

	-- `:w` to save changes (sync files)
	vim.api.nvim_create_autocmd("BufWritePost", {
		buffer = buf,
		callback = function()
			require("rubber.renderer").sync_changes(buf, require("rubber.tree").cwd)
		end,
	})
end

return M
