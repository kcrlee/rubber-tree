-- actions.lua: Actions that can be performed in Rubber
-- Author: Created with Claude's assistance
-- License: MIT

local api = vim.api
local fn = vim.fn
local tree = require("rubber.tree")
local renderer = require("rubber.renderer")

-- Actions module
local Actions = {
	state = nil, -- Will hold reference to the shared state
}

-- Set the shared state from rubber.lua
function Actions.set_state(state)
	Actions.state = state
end

-- Toggle expand/collapse directory or open file
function Actions.toggle_expand()
	local state = Actions.state
	local entry = state.get_entry_at_cursor()
	if not entry then
		return
	end

	if entry.type == "directory" then
		-- Toggle expanded state
		tree.toggle_expand(entry.path)
		state.refresh()
	else
		-- Open file in the previous window
		vim.cmd("wincmd p")
		vim.cmd("edit " .. fn.fnameescape(entry.path))
	end
end

-- Create a new file or directory after the current entry
function Actions.create_after()
	local state = Actions.state
	local entry = state.get_entry_at_cursor()
	if not entry then
		-- No entry, create at the root
		entry = { path = state.cwd, level = -1 }
	end

	-- Determine parent directory
	local parent_dir
	if entry.type == "directory" and state.expanded[entry.path] then
		parent_dir = entry.path
	else
		parent_dir = tree.parent_path(entry.path)
	end

	-- Prompt for type
	vim.cmd([[
    echohl Question
    let g:rubbertree_type = input("Create (f)ile or (d)irectory? (f/d): ")
    echohl None
  ]])

	local type = vim.g.rubbertree_type
	if type ~= "f" and type ~= "d" then
		return
	end

	-- Prompt for name
	vim.cmd([[
    echohl Question
    let g:rubbertree_name = input("Enter name: ")
    echohl None
  ]])

	local name = vim.g.rubbertree_name
	if not name or name == "" then
		return
	end

	local path = tree.path_join(parent_dir, name)

	-- Check if path already exists
	if vim.loop.fs_stat(path) then
		api.nvim_err_writeln("Path already exists: " .. path)
		return
	end

	local success

	if type == "d" then
		-- Create directory
		success = tree.create_dir(path)
	else
		-- Create file
		success = tree.create_file(path)
	end

	if not success then
		api.nvim_err_writeln("Failed to create: " .. path)
	else
		if type == "d" then
			-- Auto-expand newly created directory
			state.expanded[path] = true
		end
		state.refresh()
	end
end

-- Create a new file or directory before the current entry
function Actions.create_before()
	-- Implementation is the same as create_after for now
	-- In a more complex implementation, we could adjust positioning
	Actions.create_after()
end

-- Delete the current entry
function Actions.delete()
	local state = Actions.state
	local entry = state.get_entry_at_cursor()
	if not entry then
		return
	end

	-- Confirm deletion
	vim.cmd([[
    echohl WarningMsg
    let g:rubbertree_confirm = input("Delete ]] .. entry.name .. [[? (y/n): ")
    echohl None
  ]])

	if vim.g.rubbertree_confirm ~= "y" then
		return
	end

	-- Perform delete
	local success = tree.delete(entry.path)

	if not success then
		api.nvim_err_writeln("Failed to delete: " .. entry.path)
	else
		state.refresh()
	end
end

-- Yank (copy) the current entry
function Actions.yank()
	local state = Actions.state
	local entry = state.get_entry_at_cursor()
	if not entry then
		return
	end

	-- Store in clipboard
	state.set_clipboard({ entry }, "copy")

	vim.api.nvim_echo({ { "Yanked: " .. entry.name, "Normal" } }, true, {})
end

-- Cut the current entry
function Actions.cut()
	local state = Actions.state
	local entry = state.get_entry_at_cursor()
	if not entry then
		return
	end

	-- Store in clipboard
	state.set_clipboard({ entry }, "cut")

	vim.api.nvim_echo({ { "Cut: " .. entry.name, "Normal" } }, true, {})
end

-- Paste after the current entry
function Actions.paste_after()
	local state = Actions.state
	local clipboard = state.get_clipboard()
	if not clipboard.entries or #clipboard.entries == 0 then
		api.nvim_err_writeln("Clipboard is empty")
		return
	end

	local target_entry = state.get_entry_at_cursor()
	local target_dir

	if not target_entry then
		-- No target, paste into root
		target_dir = state.cwd
	elseif target_entry.type == "directory" and state.expanded[target_entry.path] then
		-- Target is an expanded directory, paste into it
		target_dir = target_entry.path
	else
		-- Target is a file or collapsed directory, paste into parent
		target_dir = tree.parent_path(target_entry.path)
	end

	-- Process each entry in the clipboard
	for _, entry in ipairs(clipboard.entries) do
		local dest_path = tree.path_join(target_dir, entry.name)

		-- Check if destination already exists
		if vim.loop.fs_stat(dest_path) then
			vim.cmd([[
        echohl WarningMsg
        let g:rubbertree_confirm = input("]] .. dest_path .. [[ exists. Overwrite? (y/n): ")
        echohl None
      ]])

			if vim.g.rubbertree_confirm ~= "y" then
				goto continue
			end

			-- Delete existing destination
			tree.delete(dest_path)
		end

		-- Perform the operation
		local success = false
		local err_msg = ""

		if clipboard.action == "copy" then
			success, err_msg = tree.copy(entry.path, dest_path)
		else -- cut
			success, err_msg = vim.loop.fs_rename(entry.path, dest_path)
		end

		if not success then
			api.nvim_err_writeln("Failed to " .. clipboard.action .. ": " .. (err_msg or "unknown error"))
		end

		::continue::
	end

	-- Clear clipboard after cut operation
	if clipboard.action == "cut" then
		state.clear_clipboard()
	end

	-- Refresh the tree
	state.refresh()
end

-- Paste before the current entry
function Actions.paste_before()
	-- Implementation is the same as paste_after for now
	Actions.paste_after()
end

-- Rename the current entry
function Actions.rename()
	local state = Actions.state
	local entry = state.get_entry_at_cursor()
	if not entry then
		return
	end

	-- Prompt for new name
	vim.cmd([[
    echohl Question
    let g:rubbertree_new_name = input("Rename to: ", "]] .. entry.name .. [[")
    echohl None
  ]])

	local new_name = vim.g.rubbertree_new_name
	if not new_name or new_name == "" or new_name == entry.name then
		return
	end

	-- Perform rename
	tree.rename(entry.path, new_name)
	state.refresh()
end

-- Change the current working directory
function Actions.change_dir()
	local state = Actions.state
	local entry = state.get_entry_at_cursor()
	if not entry then
		return
	end

	if entry.type == "directory" then
		state.change_dir(entry.path)
	end
end

-- Navigate to parent directory
function Actions.parent_dir()
	local state = Actions.state
	local parent = tree.parent_path(state.cwd)
	if parent and parent ~= state.cwd then
		state.change_dir(parent)
	end
end

-- Open file in a horizontal split
function Actions.open_split()
	local state = Actions.state
	local entry = state.get_entry_at_cursor()
	if not entry or entry.type ~= "file" then
		return
	end

	vim.cmd("wincmd p")
	vim.cmd("split " .. fn.fnameescape(entry.path))
end

-- Open file in a vertical split
function Actions.open_vsplit()
	local state = Actions.state
	local entry = state.get_entry_at_cursor()
	if not entry or entry.type ~= "file" then
		return
	end

	vim.cmd("wincmd p")
	vim.cmd("vsplit " .. fn.fnameescape(entry.path))
end

-- Show help information
function Actions.help()
	renderer.show_help()
end

-- Module exports
return Actions
