return function(c, opts)
  return {
    GitSignsAdd = { fg = c.base0B, bg = "none" },
    GitSignsChange = { fg = c.base0D, bg = "none" },
    GitSignsDelete = { fg = c.base08, bg = "none" },
  }
end
