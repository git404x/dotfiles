return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = {
    'nvim-lua/plenary.nvim'
  },
  config = function()
    -- Setup telescope.builtin
    local builtin = require('telescope.builtin')
    local keymap = vim.keymap -- for conciseness

    keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Fuzzy find files" })
    keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "Live grep stuff" })
  end,
}
