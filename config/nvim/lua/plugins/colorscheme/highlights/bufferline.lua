return function(c, opts)
  local bg = opts.transparent and "NONE" or c.base00
  return {
    BufferLineFill = { bg = bg },

    -- Inactive Buffers (Muted)
    BufferLineBackground = { fg = c.base03, bg = c.base01 },
    BufferLineBufferVisible = { fg = c.base04, bg = c.base01 },

    -- Active Buffers (Bright & Popping)
    BufferLineBufferSelected = { fg = c.base05, bg = c.base00, bold = true },

    BufferLineSeparator = { fg = c.base00, bg = c.base01 },
    BufferLineSeparatorVisible = { fg = c.base00, bg = c.base01 },
    BufferLineSeparatorSelected = { fg = c.base00, bg = c.base00 },

    BufferLineModified = { fg = c.base0E, bg = c.base01 },
    BufferLineModifiedVisible = { fg = c.base0E, bg = c.base01 },
    BufferLineModifiedSelected = { fg = c.base0E, bg = c.base00 },
  }
end
