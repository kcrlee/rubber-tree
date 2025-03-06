-- Place this in your NeoVim configuration directory: -- For Packer:
~/.config/nvim/lua/plugins/rubber.lua -- For Lazy:
~/.config/nvim/lua/plugins/rubber.lua

-- Using Packer return { -- Plugin configuration (Packer style) { -- Local
plugin path (replace with GitHub URL when publishing) dir =
"~/path/to/your/rubber", -- If using a plugin manager like packer, you'd use
this instead: -- 'yourusername/rubber',

    config = function()
      -- Require and set up the plugin
      local rubber = require('rubber')

      -- Configure with options
      rubber.setup({
        width = 30,            -- Width of the tree panel
        indent_width = 2,      -- Indentation width per nesting level
        show_hidden = false,   -- Whether to show hidden files by default
      })

      -- Set up keymaps
      vim.keymap.set('n', '<leader>rt', ':RubberToggle<CR>', { noremap = true, silent = true })
      vim.keymap.set('n', '<leader>rf', ':RubberRefresh<CR>', { noremap = true, silent = true })
    end,

} }

-- Using Lazy.nvim --[[ return { { "yourusername/rubber", cmd = { "RubberOpen",
"RubberToggle", "RubberClose", "RubberRefresh" }, keys = { { "<leader>rt",
":RubberToggle<CR>", desc = "Toggle Rubber" }, { "<leader>rf",
":RubberRefresh<CR>", desc = "Refresh Rubber" }, }, opts = { width = 30,
indent_width = 2, show_hidden = false, }, config = function(_, opts)
require("rubbertree").setup(opts) end, }, } --]]

## -- If you're not using a plugin manager, you can place the plugin code in: -- ~/.config/nvim/lua/rubber.lua -- And then add this to your init.lua:

## -- -- Require the plugin -- local rubber = require('rubber') -- rubber.setup({ -- width = 30, -- indent_width = 2, -- show_hidden = false, -- })

-- -- Set up keymap -- vim.keymap.set('n', '<leader>rt', ':RubberToggle<CR>', {
noremap = true, silent = true })
