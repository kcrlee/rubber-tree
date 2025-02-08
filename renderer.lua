local M = {}

local function get_files(dir)
	local handle = io.popen('ls -1 "' .. dir .. '"')
	if not handle then
		return {}
	end
	local result = {}
	for filename in handle:lines() do
		table.insert(result, filename)
	end
	handle:close()
	return result
end

-- Render directory in the buffer
M.render_tree = function(buf, dir)
	local files = get_files(dir)

	-- Enable editing
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, files)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Sync filesystem changes on save (`:w`)
M.sync_changes = function(buf, dir)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local actual_files = get_files(dir)

	-- Detect deletions and renames
	for _, file in ipairs(actual_files) do
		if not vim.tbl_contains(lines, file) then
			os.remove(dir .. "/" .. file)
		end
	end

	-- Detect new files
	for _, new_file in ipairs(lines) do
		if not vim.tbl_contains(actual_files, new_file) then
			local f = io.open(dir .. "/" .. new_file, "w")
			if f then
				f:close()
			end
		end
	end

	-- Refresh the buffer
	M.render_tree(buf, dir)
end

return M
