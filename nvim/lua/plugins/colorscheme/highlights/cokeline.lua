return function(c, opts)
  local bg = opts.transparent and "NONE" or c.base00
  return {
    TabLine = { fg = c.base03, bg = c.base01 },
    TabLineFill = { bg = bg },
    TabLineSel = { fg = c.base05, bg = c.base00, bold = true },

    CokelineFocus = { fg = c.base0B, bg = c.base00, bold = true },
    CokelineUnfocus = { fg = c.base03, bg = c.base01 }, -- Muted inactive tabs
    CokelineError = { fg = c.base08, bg = c.base01 },
    CokelineWarn = { fg = c.base0A, bg = c.base01 },
  }
end
