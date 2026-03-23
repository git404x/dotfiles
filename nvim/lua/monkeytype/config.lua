local M = {}

M.defaults = {
  -- We will add more config options here later (times, modes, etc.)
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})

  -- Define default highlight groups
  vim.api.nvim_set_hl(0, "MonkeytypeUntyped", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "MonkeytypeTyped", { link = "String", default = true })
  vim.api.nvim_set_hl(0, "MonkeytypeMistake", { link = "ErrorMsg", default = true })
  vim.api.nvim_set_hl(0, "MonkeytypeCursor", { link = "Cursor", default = true, reverse = true })
end

return M
