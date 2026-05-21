return function(c, opts)
  local prompt_bg = c.base01
  local results_bg = opts.transparent and "NONE" or c.base00
  local border_fg = opts.telescope_borders and c.base02 or results_bg
  local prompt_border_fg = opts.telescope_borders and c.base02 or prompt_bg

  return {
    TelescopePromptNormal = { bg = prompt_bg, fg = c.base05 },
    TelescopePromptBorder = { bg = prompt_bg, fg = prompt_border_fg },
    TelescopePromptTitle = { bg = c.base0B, fg = c.base00, bold = true },
    TelescopePreviewNormal = { bg = results_bg },
    TelescopePreviewBorder = { bg = results_bg, fg = border_fg },
    TelescopePreviewTitle = { bg = c.base0D, fg = c.base00, bold = true },
    TelescopeResultsNormal = { bg = results_bg },
    TelescopeResultsBorder = { bg = results_bg, fg = border_fg },
    TelescopeSelection = { bg = c.base02, fg = c.base05, bold = true },
  }
end
