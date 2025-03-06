-- tree.lua: File system operations for Rubber
-- Author: Created with Claude's assistance
-- License: MIT

local uv = vim.loop
local api = vim.api

-- Tree module
local Tree = {
	state = nil, -- Will hold reference to the shared state
}

-- Set the shared state from rubber.lua
function Tree.set_state(state)
	Tree.state = state
end

-- Path utilities
local Path = {}

-- Joins path components correctly based on OS
function Path.join(...)
	local path_sep = package.config:sub(1, 1) -- Get OS-specific separator
	local args = { ... }
	if #args == 0 then
		return ""
	end

	local result = args[1]
	for i = 2, #args do
		-- Avoid double separators
		if result:sub(-1) ~= path_sep and args[i]:sub(1, 1) ~= path_sep then
			result = result .. path_sep .. args[i]
		else
			result = result .. args[i]
		end
	end

	return result
end

-- Gets the parent directory of a path
function Path.parent(path)
	local path_sep = package.config:sub(1, 1)
	-- Remove trailing slash if present
	if path:sub(-1) == path_sep then
		path = path:sub(1, -2)
	end

	local parent = path:match("(.*)" .. path_sep .. ".-$")
	return parent or path
end

-- Gets just the filename from a path
function Path.filename(path)
	local path_sep = package.config:sub(1, 1)
	return path:match(".*" .. path_sep .. "(.-)$") or path
end

-- Expose path functions to the module
Tree.path_join = Path.join
Tree.parent_path = Path.parent
Tree.filename = Path.filename

-- Check if path is a directory
function Tree.is_dir(path)
	local stat = uv.fs_stat(path)
	return stat and stat.type == "directory" or false
end

-- Check if path is a file
function Tree.is_file(path)
	local stat = uv.fs_stat(path)
	return stat and stat.type == "file" or false
end

-- List all entries in a directory
function Tree.list_dir(path)
	local entries = {}
	local handle = uv.fs_scandir(path)

	if not handle then
		return entries
	end

	while true do
		local name, type = uv.fs_scandir_next(handle)
		if not name then
			break
		end

		-- Skip hidden files if not showing them
		if Tree.state.show_hidden or name:sub(1, 1) ~= "." then
			local full_path = Path.join(path, name)
			table.insert(entries, {
				name = name,
				path = full_path,
				type = type or (Tree.is_dir(full_path) and "directory" or "file"),
			})
		end
	end

	-- Sort entries: directories first, then files, alphabetically
	table.sort(entries, function(a, b)
		if a.type == b.type then
			return a.name:lower() < b.name:lower()
		else
			return a.type == "directory"
		end
	end)

	return entries
end

-- Recursive function to build a tree structure
function Tree.build_tree(root_path, level, result, parent_path)
	level = level or 0
	result = result or {}
	parent_path = parent_path or ""

	local entries = Tree.list_dir(root_path)

	for _, entry in ipairs(entries) do
		-- Create relative path from root
		local rel_path = parent_path ~= "" and Path.join(parent_path, entry.name) or entry.name

		-- Add entry to result
		table.insert(result, {
			name = entry.name,
			path = entry.path,
			type = entry.type,
			level = level,
			rel_path = rel_path,
			expanded = false,
			parent = parent_path,
		})

		-- Recursively add children if directory is expanded
		if entry.type == "directory" and Tree.state.expanded[entry.path] then
			Tree.build_tree(entry.path, level + 1, result, rel_path)
		end
	end

	return result
end

-- Creates a new file
function Tree.create_file(path)
	local fd = uv.fs_open(path, "w", 420) -- 0644 permissions
	if fd then
		uv.fs_close(fd)
		return true
	end
	return false
end

-- Creates a new directory
function Tree.create_dir(path)
	return uv.fs_mkdir(path, 493) -- 0755 permissions
end

-- Delete a file or directory recursively
function Tree.delete(path)
	local stat = uv.fs_stat(path)
	if not stat then
		return true
	end -- Already gone

	if stat.type == "directory" then
		-- Delete contents first
		local handle = uv.fs_scandir(path)
		if handle then
			while true do
				local name = uv.fs_scandir_next(handle)
				if not name then
					break
				end

				local child_path = Path.join(path, name)
				local success = Tree.delete(child_path)
				if not success then
					return false
				end
			end
		end

		-- Delete the empty directory
		return uv.fs_rmdir(path)
	else
		-- Delete file
		return uv.fs_unlink(path)
	end
end

-- Copy a file or directory recursively
function Tree.copy(src, dst)
	local stat = uv.fs_stat(src)
	if not stat then
		return false, "Source doesn't exist"
	end

	if stat.type == "directory" then
		-- Create destination directory
		local success, err = uv.fs_mkdir(dst, stat.mode)
		if not success then
			return false, err
		end

		-- Copy contents
		local handle = uv.fs_scandir(src)
		if not handle then
			return false, "Failed to scan directory"
		end

		while true do
			local name = uv.fs_scandir_next(handle)
			if not name then
				break
			end

			local src_child = Path.join(src, name)
			local dst_child = Path.join(dst, name)

			local ok, error = Tree.copy(src_child, dst_child)
			if not ok then
				return false, error
			end
		end

		return true
	else
		-- Copy file
		local fd_src = uv.fs_open(src, "r", 0)
		if not fd_src then
			return false, "Failed to open source"
		end

		local fd_dst = uv.fs_open(dst, "w", stat.mode)
		if not fd_dst then
			uv.fs_close(fd_src)
			return false, "Failed to create destination"
		end

		-- Read source file
		local stat_src = uv.fs_fstat(fd_src)
		local chunk_size = 65536 -- 64KB chunks
		local remaining = stat_src.size

		while remaining > 0 do
			local size = math.min(chunk_size, remaining)
			local data = uv.fs_read(fd_src, size, -1)
			if not data then
				uv.fs_close(fd_src)
				uv.fs_close(fd_dst)
				return false, "Failed to read source"
			end

			local written = uv.fs_write(fd_dst, data, -1)
			if not written then
				uv.fs_close(fd_src)
				uv.fs_close(fd_dst)
				return false, "Failed to write to destination"
			end

			remaining = remaining - size
		end

		uv.fs_close(fd_src)
		uv.fs_close(fd_dst)
		return true
	end
end

-- Rename a file or directory
function Tree.rename(old_path, new_name)
	local new_path = Path.join(Path.parent(old_path), new_name)

	-- Check if target already exists
	if uv.fs_stat(new_path) then
		api.nvim_err_writeln("Cannot rename: target already exists")
		return false
	end

	-- Perform rename
	local ok, err = uv.fs_rename(old_path, new_path)
	if not ok then
		api.nvim_err_writeln("Failed to rename: " .. (err or "unknown error"))
		return false
	end

	-- If it was an expanded directory, transfer expanded state
	if Tree.state.expanded[old_path] then
		Tree.state.expanded[old_path] = nil
		Tree.state.expanded[new_path] = true
	end

	return true
end

-- Toggle expand state of a directory
function Tree.toggle_expand(path)
	if Tree.is_dir(path) then
		Tree.state.expanded[path] = not Tree.state.expanded[path]
		return true
	end
	return false
end

-- Module exports
return Tree
