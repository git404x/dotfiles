return {
  "echasnovski/mini.icons",
  version = false,
  lazy = false,
  priority = 1000, -- initialize before UI
  config = function()
    local icons = require("mini.icons")
    icons.setup({})
    -- intercept calls for nvim-web-devicons
    icons.mock_nvim_web_devicons()
  end,
}
