local M = {}

M.buf = nil
M.win = nil

function M.open_test_window()
  -- Create a new empty buffer (listed=false, scratch=true)
  M.buf = vim.api.nvim_create_buf(false, true)

  -- Open it in the current window
  M.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(M.win, M.buf)

  -- Set buffer options for a clean UI
  vim.bo[M.buf].filetype = "monkeytype"
  vim.bo[M.buf].swapfile = false
  vim.wo[M.win].number = true
  vim.wo[M.win].relativenumber = false
  vim.wo[M.win].wrap = true
  vim.wo[M.win].spell = false
  vim.wo[M.win].signcolumn = "no"

  -- Force normal mode to start
  vim.cmd("stopinsert")

  print("Monkeytype buffer initialized!")

  local core = require("monkeytype.core")
  core.start_test(M.buf)
end

return M
