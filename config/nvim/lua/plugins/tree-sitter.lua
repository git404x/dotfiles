return {
  "nvim-treesitter/nvim-treesitter",
  build= ":TSUpdate",
  config = function()
    -- Setup treesitter
    local config = require("nvim-treesitter.configs")
    config.setup({
      ensure_installed = {"lua", "javascript", "json", "css", "html"},
      highlight = { enable = true },
      indent = { enable = true }
    })
  end,
}
