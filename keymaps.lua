-- keymaps.lua: Keyboard mappings for Rubber
-- Author: Created with Claude's assistance
-- License: MIT

local api = vim.api

-- Keymaps module
local Keymaps = {}

-- Set up buffer-local mappings
function Keymaps.setup_buffer_mappings(buf)
	local function map(mode, key, action)
		api.nvim_buf_set_keymap(buf, mode, key, action, {
			noremap = true,
			silent = true,
		})
	end

	-- Expand/collapse or open file with Enter
	map("n", "<CR>", ':lua require("rubber.actions").toggle_expand()<CR>')

	-- Create new file or directory
	map("n", "a", ':lua require("rubber.actions").create_after()<CR>')
	map("n", "A", ':lua require("rubber.actions").create_before()<CR>')

	-- Delete the current entry
	map("n", "d", ':lua require("rubber.actions").delete()<CR>')
	map("n", "D", ':lua require("rubber.actions").delete()<CR>')

	-- Yank (copy) the current entry
	map("n", "y", ':lua require("rubber.actions").yank()<CR>')

	-- Cut the current entry
	map("n", "x", ':lua require("rubber.actions").cut()<CR>')

	-- Paste after or before current entry
	map("n", "p", ':lua require("rubber.actions").paste_after()<CR>')
	map("n", "P", ':lua require("rubber.actions").paste_before()<CR>')

	-- Rename current entry (also works via standard editing)
	map("n", "r", ':lua require("rubber.actions").rename()<CR>')

	-- Refresh the tree
	map("n", "R", ":RubberRefresh<CR>")

	-- Toggle hidden files
	map("n", ".", ':lua require("rubber").toggle_hidden()<CR>')

	-- Change working directory
	map("n", "cd", ':lua require("rubber.actions").change_dir()<CR>')

	-- Go to parent directory
	map("n", "-", ':lua require("rubber.actions").parent_dir()<CR>')

	-- Open file in a new split
	map("n", "s", ':lua require("rubber.actions").open_split()<CR>')
	map("n", "v", ':lua require("rubber.actions").open_vsplit()<CR>')

	-- Help
	map("n", "?", ':lua require("rubber.actions").help()<CR>')
end

-- Module exports
return Keymaps
