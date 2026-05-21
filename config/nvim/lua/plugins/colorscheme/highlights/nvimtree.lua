return function(c, opts)
  local bg = opts.transparent and "NONE" or c.base00
  return {
    NvimTreeNormal = { fg = c.base05, bg = bg }, -- Filenames are bright again
    NvimTreeNormalNC = { fg = c.base05, bg = bg },

    NvimTreeFolderIcon = { fg = c.base0C }, -- Softer folder color
    NvimTreeFolderName = { fg = c.base05 },
    NvimTreeOpenedFolderName = { fg = c.base05, bold = true },
    NvimTreeEmptyFolderName = { fg = c.base03 },

    NvimTreeIndentMarker = { fg = c.base02 }, -- Muted indents
    NvimTreeRootFolder = { fg = c.base0E, bold = true },
    NvimTreeGitDirty = { fg = c.base09 },
    NvimTreeGitNew = { fg = c.base0B },
    NvimTreeGitDeleted = { fg = c.base08 },
    NvimTreeOpenedFile = { fg = c.base0B, bold = true },
    NvimTreeCursorLine = { bg = c.base01 },
    NvimTreeWinSeparator = { fg = c.base00, bg = bg },
  }
end
