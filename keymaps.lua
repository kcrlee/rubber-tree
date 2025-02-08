local M = {}

M.setup = function(buf)
	local opts = { noremap = true, silent = true }

	-- Global mapping
	vim.api.nvim_set_keymap("n", "-", ":lua require('rubber.tree').open()<CR>", opts)

	-- Buffer-local mapping
	if buf then
		vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", ":lua require('rubber.actions').open()<CR>", opts)
	end
end

return M -- ✅ This must be present!
