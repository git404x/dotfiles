return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  config = function()
    require("lualine").setup({ options = { theme = "auto" } })
    -- Re-apply the active theme now that lualine is loaded.
    -- The highlights/lualine.lua pcall will succeed this time.
    if _G.LoadTheme and vim.g.colors_name then
      _G.LoadTheme(vim.g.colors_name, false)
    end
  end,
}
