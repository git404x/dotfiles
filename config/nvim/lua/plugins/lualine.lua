return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons'
  },
  config = function()
    -- setup lualine.nvim
    require('lualine').setup({
      options = {
        theme = 'auto',
      }
    })
  end,
}


