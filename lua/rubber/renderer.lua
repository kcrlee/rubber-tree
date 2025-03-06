-- renderer.lua: Buffer and rendering related functions for Rubber
-- Author: Created with Claude's assistance
-- License: MIT

local api = vim.api
local tree = require("rubber.tree")
local keymaps = require("rubber.keymaps")

local Renderer = {
	state = nil, -- Will hold reference to the shared state
}

-- Set the shared state from rubber.lua
function Renderer.set_state(state)
	Renderer.state = state
end

-- Initializes or retrieves the buffer for the file tree
function Renderer.get_or_create_buffer()
	if Renderer.state.buffer and api.nvim_buf_is_valid(Renderer.state.buffer) then
		return Renderer.state.buffer
	end

	-- Create a new buffer
	local buf = api.nvim_create_buf(false, true)

	-- Set buffer options
	api.nvim_buf_set_name(buf, "Rubber")
	api.nvim_buf_set_option(buf, "filetype", "rubber")
	api.nvim_buf_set_option(buf, "buftype", "acwrite") -- Special buffer, but writable
	api.nvim_buf_set_option(buf, "swapfile", false)

	-- Make the buffer modifiable
	api.nvim_buf_set_option(buf, "modifiable", true)

	-- Set up buffer mappings
	keymaps.setup_buffer_mappings(buf)

	return buf
end

-- Render the file tree to the buffer
function Renderer.render_tree()
	local state = Renderer.state
	if not state.buffer or not api.nvim_buf_is_valid(state.buffer) then
		return
	end

	-- Save the cursor position
	local cursor_pos = nil
	if state.window and api.nvim_win_is_valid(state.window) then
		cursor_pos = api.nvim_win_get_cursor(state.window)
	end

	-- Make the buffer modifiable
	api.nvim_buf_set_option(state.buffer, "modifiable", true)

	-- Clear the buffer
	api.nvim_buf_set_lines(state.buffer, 0, -1, false, {})

	-- Add current directory header
	local header = "RUBBER: " .. state.cwd
	api.nvim_buf_set_lines(state.buffer, 0, 1, false, { header, "" })

	-- Build tree structure
	local entries = tree.build_tree(state.cwd)
	state.entries = entries

	-- Clear mapping tables
	local line_to_entry = {}
	local entry_to_line = {}

	-- Render entries
	local lines = {}
	for i, entry in ipairs(entries) do
		-- Calculate indentation
		local indent = string.rep(" ", entry.level * state.indent_width)

		-- Create entry prefix
		local prefix = ""
		if entry.type == "directory" then
			prefix = state.expanded[entry.path] and "▼ " or "▶ "
		else
			prefix = "  "
		end

		-- Create line text
		local line_text = indent .. prefix .. entry.name
		table.insert(lines, line_text)

		-- Map line to entry and vice versa
		local line_idx = #lines + 2 -- +2 for header (includes the blank line)
		line_to_entry[line_idx] = entry
		entry_to_line[entry.path] = line_idx
	end

	-- Add lines to buffer
	api.nvim_buf_set_lines(state.buffer, 2, 2, false, lines)

	-- Update the state with the mappings
	state.line_to_entry = line_to_entry
	state.entry_to_line = entry_to_line

	-- Reset modified state
	api.nvim_buf_set_option(state.buffer, "modified", false)

	-- Keep the buffer modifiable for user edits
	api.nvim_buf_set_option(state.buffer, "modifiable", true)

	-- Restore cursor position if it was saved
	if cursor_pos and state.window and api.nvim_win_is_valid(state.window) then
		-- Make sure the cursor position is valid
		local line_count = api.nvim_buf_line_count(state.buffer)
		if cursor_pos[1] > line_count then
			cursor_pos[1] = line_count
		end
		api.nvim_win_set_cursor(state.window, cursor_pos)
	end
end

-- Render help text in a new buffer
function Renderer.show_help()
	local help_text = {
		"Rubber Help",
		"===========",
		"",
		"Navigation:",
		"  <CR>    Toggle directory / Open file",
		"  -       Go to parent directory",
		"",
		"File operations:",
		"  a       Create file/directory after current entry",
		"  A       Create file/directory before current entry",
		"  d, D    Delete entry under cursor",
		"  r       Rename entry under cursor",
		"  y       Yank (copy) entry",
		"  x       Cut entry",
		"  p       Paste after current position",
		"  P       Paste before current position",
		"",
		"Window commands:",
		"  s       Open file in horizontal split",
		"  v       Open file in vertical split",
		"",
		"Other:",
		"  R       Refresh the view",
		"  .       Toggle hidden files",
		"  cd      Change directory to the one under cursor",
		"  ?       Show this help",
	}

	vim.cmd("split Rubber-Help")
	local help_buf = api.nvim_get_current_buf()
	api.nvim_buf_set_lines(help_buf, 0, -1, false, help_text)
	api.nvim_buf_set_option(help_buf, "buftype", "nofile")
	api.nvim_buf_set_option(help_buf, "modifiable", false)
end

-- Module exports
return Renderer
