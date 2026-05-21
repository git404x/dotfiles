return function(c, opts)
  return {
    Pmenu = { fg = c.base05, bg = c.base01 },
    PmenuSel = { fg = c.base00, bg = c.base0D, bold = true },
    PmenuBorder = { fg = c.base02, bg = c.base01 },
    CmpItemAbbrMatch = { fg = c.base0D, bold = true },
    CmpItemAbbrMatchFuzzy = { fg = c.base0D, bold = true },
    CmpItemKindCopilot = { fg = c.base0B },
  }
end
