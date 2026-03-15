return {
  "nvim-theme-engine",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/colorscheme",
  lazy = false,
  priority = 1000,
  config = function()
    -- CHOOSE YOUR THEME HERE
    local active_theme = "fruit_salad"

    -- Load the palette dynamically from the themes directory
    local ok, theme = pcall(require, "plugins.colorscheme.themes." .. active_theme)
    if not ok then
      vim.notify("Theme '" .. active_theme .. "' not found!", vim.log.levels.ERROR)
      return
    end

    local c = theme.colors

    -- RESET EXISTING THEMES
    vim.cmd("hi clear")
    if vim.fn.exists("syntax_on") then
      vim.cmd("syntax reset")
    end
    vim.o.termguicolors = true
    vim.o.background = theme.polarity
    vim.g.colors_name = theme.name

    -- THE HIGHLIGHT ENGINE (Inspired by Yoda/Gruvbox architecture)
    local function hl(group, opts)
      vim.api.nvim_set_hl(0, group, opts)
    end

    -- --- Editor UI ---
    hl("Normal", { fg = c.base05, bg = "none" }) -- 'none' allows your terminal OLED black to show through
    hl("NormalFloat", { fg = c.base05, bg = c.base01 })
    hl("ColorColumn", { bg = c.base01 })
    hl("CursorLine", { bg = c.base01 })
    hl("CursorColumn", { bg = c.base01 })
    hl("LineNr", { fg = c.base03 })
    hl("CursorLineNr", { fg = c.base0B, bold = true })
    hl("Visual", { bg = c.base02 })
    hl("Search", { fg = c.base00, bg = c.base0A })
    hl("IncSearch", { fg = c.base00, bg = c.base09 })
    hl("StatusLine", { fg = c.base04, bg = c.base01 })
    hl("StatusLineNC", { fg = c.base03, bg = c.base00 })
    hl("SignColumn", { bg = "none" })
    hl("Pmenu", { fg = c.base05, bg = c.base01 })
    hl("PmenuSel", { fg = c.base00, bg = c.base0D })

    -- --- Standard Syntax ---
    hl("Comment", { fg = c.base03, italic = true })
    hl("String", { fg = c.base0B })
    hl("Character", { fg = c.base0B })
    hl("Number", { fg = c.base09 })
    hl("Float", { fg = c.base09 })
    hl("Boolean", { fg = c.base09 })
    hl("Identifier", { fg = c.base08 })
    hl("Function", { fg = c.base0D })
    hl("Statement", { fg = c.base0E })
    hl("Conditional", { fg = c.base0E })
    hl("Repeat", { fg = c.base0E })
    hl("Label", { fg = c.base0E })
    hl("Operator", { fg = c.base05 })
    hl("Keyword", { fg = c.base0E })
    hl("Exception", { fg = c.base08 })
    hl("PreProc", { fg = c.base0A })
    hl("Type", { fg = c.base0A })
    hl("Special", { fg = c.base0C })

    -- --- Treesitter (Base16 mapping) ---
    hl("@variable", { fg = c.base05 })
    hl("@variable.builtin", { fg = c.base08 })
    hl("@function.call", { fg = c.base0D })
    hl("@property", { fg = c.base08 })
    hl("@field", { fg = c.base08 })
    hl("@constructor", { fg = c.base0C })
    hl("@punctuation", { fg = c.base0F })

    -- --- LSP Diagnostics ---
    hl("DiagnosticError", { fg = c.base08 })
    hl("DiagnosticWarn", { fg = c.base0A })
    hl("DiagnosticInfo", { fg = c.base0D })
    hl("DiagnosticHint", { fg = c.base0C })
    hl("DiagnosticUnderlineError", { sp = c.base08, undercurl = true })
    hl("DiagnosticUnderlineWarn", { sp = c.base0A, undercurl = true })

    -- --- GitSigns ---
    hl("GitSignsAdd", { fg = c.base0B, bg = "none" })
    hl("GitSignsChange", { fg = c.base0D, bg = "none" })
    hl("GitSignsDelete", { fg = c.base08, bg = "none" })
  end,
}
