return {
  "ellisonleao/gruvbox.nvim",
  priority = 1000,
  config = function()
    -- Setup colorscheme
    require("gruvbox").setup({
      background = dark,
      terminal_colors = true, -- add neovim terminal colors
      undercurl = true,
      underline = true,
      bold = true,
      italic = {
        strings = false,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
      },
      strikethrough = true,
      invert_selection = false,
      invert_signs = false,
      invert_tabline = false,
      inverse = true, -- invert background for search, diffs, statuslines and errors
      contrast = "hard", -- can be "hard", "soft" or empty string
      palette_overrides = {},
      overrides = {},
      dim_inactive = false,
      transparent_mode = false,
    })
    -- setup must be called before loading
    -- vim.o.background = "dark" -- or "light"
    vim.cmd("colorscheme gruvbox")
  end,
}
