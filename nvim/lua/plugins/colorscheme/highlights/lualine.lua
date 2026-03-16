return function(c, opts)
  local bg = opts.transparent and "NONE" or c.base00
  local theme = {
    normal = {
      a = { bg = c.base0D, fg = c.base00, gui = "bold" },
      b = { bg = c.base02, fg = c.base05 },
      c = { bg = bg, fg = c.base05 },
    },
    insert = {
      a = { bg = c.base0B, fg = c.base00, gui = "bold" },
      b = { bg = c.base02, fg = c.base05 },
      c = { bg = bg, fg = c.base05 },
    },
    visual = {
      a = { bg = c.base0E, fg = c.base00, gui = "bold" },
      b = { bg = c.base02, fg = c.base05 },
      c = { bg = bg, fg = c.base05 },
    },
    replace = {
      a = { bg = c.base08, fg = c.base00, gui = "bold" },
      b = { bg = c.base02, fg = c.base05 },
      c = { bg = bg, fg = c.base05 },
    },
    inactive = {
      a = { bg = c.base01, fg = c.base04, gui = "bold" },
      b = { bg = c.base01, fg = c.base04 },
      c = { bg = bg, fg = c.base04 },
    },
  }
  local ok, lualine = pcall(require, "lualine")
  if ok then
    lualine.setup({ options = { theme = theme } })
  end
  return {}
end
