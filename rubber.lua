-- rubber.lua: Core functionality for the Rubber plugin
-- Author: Created with Claude's assistance
-- License: MIT

local api = vim.api
local fn = vim.fn

local tree = require("rubber.tree")
local renderer = require("rubber.renderer")
local actions = require("rubber.actions")

-- Plugin namespace
local Rubber = {
	buffer = nil, -- Buffer ID for the tree
	window = nil, -- Window ID for the tree
	width = 30, -- Default width of the tree
	is_open = false, -- State of the tree
	cwd = fn.getcwd(), -- Current working directory
	entries = {}, -- File and directory entries
	line_to_entry = {}, -- Maps buffer line numbers to entries
	entry_to_line = {}, -- Maps entries to buffer line numbers
	indent_width = 2, -- Indentation width per level
	expanded = {}, -- Tracks which directories are expanded
	show_hidden = false, -- Whether to show hidden files
	clipboard = { -- For yank/put operations
		entries = {},
		action = nil, -- "copy" or "cut"
	},
}

-- Initializes Rubber with user options
function Rubber.init(opts)
	-- Apply user options
	for k, v in pairs(opts) do
		if Rubber[k] ~= nil then
			Rubber[k] = v
		end
	end

	-- Share the state with other modules
	tree.set_state(Rubber)
	renderer.set_state(Rubber)
	actions.set_state(Rubber)
end

-- Updates the entries and mappings
function Rubber.update_entries(entries)
	Rubber.entries = entries
end

-- Updates the line mappings
function Rubber.update_mappings(line_to_entry, entry_to_line)
	Rubber.line_to_entry = line_to_entry
	Rubber.entry_to_line = entry_to_line
end

-- Get entry at cursor
function Rubber.get_entry_at_cursor()
	if not Rubber.window or not api.nvim_win_is_valid(Rubber.window) then
		return nil
	end

	local cursor = api.nvim_win_get_cursor(Rubber.window)
	local line_num = cursor[1]

	return Rubber.line_to_entry[line_num]
end

-- Handle visual mode yank/delete operations
function Rubber.handle_visual_yank_delete()
	-- Get visual selection
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	-- Check that we have valid positions
	if start_pos[1] == 0 or end_pos[1] == 0 then
		return {}
	end

	local start_line = start_pos[2]
	local end_line = end_pos[2]

	-- Collect all entries in the selection
	local entries = {}
	for i = start_line, end_line do
		local entry = Rubber.line_to_entry[i]
		if entry then
			table.insert(entries, entry)
		end
	end

	return entries
end

-- Sets clipboard content
function Rubber.set_clipboard(entries, action)
	Rubber.clipboard = {
		entries = entries,
		action = action,
	}
end

-- Gets clipboard content
function Rubber.get_clipboard()
	return Rubber.clipboard
end

-- Clears clipboard
function Rubber.clear_clipboard()
	Rubber.clipboard = {
		entries = {},
		action = nil,
	}
end

-- Open the file tree
function Rubber.open()
	if Rubber.is_open and Rubber.window and api.nvim_win_is_valid(Rubber.window) then
		-- Already open, just focus the window
		api.nvim_set_current_win(Rubber.window)
		return
	end

	-- Get or create the buffer
	local buf = renderer.get_or_create_buffer()
	Rubber.buffer = buf

	-- Create a window on the left
	vim.cmd("topleft " .. Rubber.width .. "vsplit")
	Rubber.window = api.nvim_get_current_win()
	api.nvim_win_set_buf(Rubber.window, buf)

	-- Set window options
	api.nvim_win_set_option(Rubber.window, "number", false)
	api.nvim_win_set_option(Rubber.window, "relativenumber", false)
	api.nvim_win_set_option(Rubber.window, "cursorline", true)
	api.nvim_win_set_option(Rubber.window, "winfixwidth", true)

	-- Render the tree
	Rubber.refresh()

	Rubber.is_open = true
end

-- Close the file tree
function Rubber.close()
	if Rubber.window and api.nvim_win_is_valid(Rubber.window) then
		api.nvim_win_close(Rubber.window, true)
	end
	Rubber.window = nil
	Rubber.is_open = false
end

-- Toggle the file tree
function Rubber.toggle()
	if Rubber.is_open then
		Rubber.close()
	else
		Rubber.open()
	end
end

-- Refresh the file tree
function Rubber.refresh()
	renderer.render_tree()
end

-- Toggle display of hidden files
function Rubber.toggle_hidden()
	Rubber.show_hidden = not Rubber.show_hidden
	Rubber.refresh()
end

-- Change directory
function Rubber.change_dir(path)
	Rubber.cwd = path
	Rubber.refresh()
end

-- Apply changes when buffer is written
function Rubber.apply_changes()
	-- Get the buffer content
	local lines = api.nvim_buf_get_lines(Rubber.buffer, 0, -1, false)

	-- Parse the header line to get the current directory
	local header = lines[1]
	local cwd = header:match("RUBBER: (.*)")

	if cwd and cwd ~= Rubber.cwd then
		-- Directory changed in the header
		if tree.is_dir(cwd) then
			Rubber.cwd = cwd
			Rubber.refresh()
		else
			api.nvim_err_writeln("Invalid directory: " .. cwd)
		end
		return
	end

	-- For each line in the buffer, check if file/dir names have changed
	for i = 3, #lines do -- Start after header
		local line = lines[i]
		local entry = Rubber.line_to_entry[i]

		if entry then
			-- Extract the entry name from the line
			local level = entry.level
			local indent = level * Rubber.indent_width
			local prefix_len = entry.type == "directory" and 2 or 2 -- "▼ " or "▶ " or "  "
			local start_idx = indent + prefix_len + 1

			-- Get the name from the line
			local name_in_buffer = line:sub(start_idx)

			-- If name has changed, rename the file/directory
			if name_in_buffer ~= entry.name and name_in_buffer ~= "" then
				tree.rename(entry.path, name_in_buffer)
			end
		end
	end

	-- Refresh the tree to show the changes
	Rubber.refresh()
end

-- Module exports
return Rubber
