-- bufferline replacement
return {
  "willothy/nvim-cokeline",
  event = "BufReadPre",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for v0.4.0+
    "kyazdani42/nvim-web-devicons", -- If you want devicons
    "stevearc/resession.nvim", -- Optional, for persistent history
  },

  config = function()
    local cokeline = require("cokeline")
    local get_hex = require('cokeline.hlgroups').get_hl_attr

    cokeline.setup({
      sidebar = {
        filetype = {'NvimTree', 'neo-tree'},
        components = {
          {
            text = function(buf)
              return buf.filetype
            end,
            bg = function()
              return get_hex('NvimTreeNormal', 'bg')
            end,
            bold = true,
          },
        }
      },
    })
  end,
}
