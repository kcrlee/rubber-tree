-- init.lua: Entry point for the Rubber plugin
-- Author: Created with Claude's assistance
-- License: MIT

-- Import the submodules
local rubber = require("rubber.rubber")
local actions = require("rubber.actions")
local keymaps = require("rubber.keymaps")

-- Main setup function
local function setup(opts)
	opts = opts or {}

	-- Initialize the plugin with options
	rubber.init(opts)

	-- Set up commands
	create_commands()

	-- Set up autocmds
	setup_autocmds()

	-- Return the API
	return rubber
end

-- Setup plugin commands
local function create_commands()
	vim.cmd([[
    command! RubberOpen lua require('rubber').open()
    command! RubberClose lua require('rubber').close()
    command! RubberToggle lua require('rubber').toggle()
    command! RubberRefresh lua require('rubber').refresh()
  ]])
end

-- Setup autocmds
local function setup_autocmds()
	vim.cmd([[
    augroup Rubber
      autocmd!
      autocmd BufWriteCmd Rubber lua require('rubber').apply_changes()
      autocmd BufModifiedSet Rubber setlocal nomodified
    augroup END
  ]])

	-- Set up syntax highlighting
	vim.cmd([[
    augroup RubberSyntax
      autocmd!
      autocmd FileType rubber call s:SetupSyntax()
    augroup END

    function! s:SetupSyntax()
      syntax match RubberHeader /^RUBBER:.*$/
      syntax match RubberDirectory /▼ .*$/
      syntax match RubberDirectory /▶ .*$/
      syntax match RubberFile /  .*$/

      highlight default link RubberHeader Title
      highlight default link RubberDirectory Directory
      highlight default link RubberFile Normal
    endfunction
  ]])

	-- Add functions to detect file changes while editing the buffer
	vim.api.nvim_create_autocmd("TextChanged", {
		pattern = "RubberTree",
		callback = function()
			-- Mark buffer as modified to trigger BufWriteCmd later
			vim.api.nvim_buf_set_option(0, "modified", true)
		end,
	})

	vim.api.nvim_create_autocmd("TextChangedI", {
		pattern = "RubberTree",
		callback = function()
			-- Mark buffer as modified to trigger BufWriteCmd later
			vim.api.nvim_buf_set_option(0, "modified", true)
		end,
	})

	-- Handle drag and drop operations in visual mode
	vim.api.nvim_create_autocmd("TextYankPost", {
		pattern = "RubberTree",
		callback = function()
			-- Get register used
			local reg = vim.v.event.regname
			local regtype = vim.v.event.regtype

			-- Only handle linewise operations
			if regtype ~= "V" then
				return
			end

			-- If this was a delete operation in visual mode
			if vim.v.event.operator == "d" and vim.fn.mode() == "n" then
				-- Get yanked text
				local yanked = vim.fn.getreg(reg)

				-- Find entries that were yanked/deleted
				local entries = rubber.handle_visual_yank_delete()
				if entries and #entries > 0 then
					-- Store in clipboard for cut
					rubber.set_clipboard(entries, "cut")

					-- Immediately refresh to prevent invalid buffer state
					vim.schedule(function()
						rubber.refresh()
					end)
				end
			end
		end,
	})
end

-- Module exports
return {
	setup = setup,
	open = rubber.open,
	close = rubber.close,
	toggle = rubber.toggle,
	refresh = rubber.refresh,
	apply_changes = rubber.apply_changes,
	actions = actions,
}
