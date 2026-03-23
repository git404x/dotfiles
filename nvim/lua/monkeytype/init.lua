local M = {}
local config = require("monkeytype.config")
local ui = require("monkeytype.ui")

function M.setup(opts)
  -- 1. Initialize configuration and highlights
  config.setup(opts)

  -- 2. Create the user command to launch it
  vim.api.nvim_create_user_command("Monkeytype", function()
    M.start()
  end, { desc = "Start Monkeytype typing test" })
end

function M.start()
  -- We will call our UI module to open the window here
  ui.open_test_window()
end

return M
