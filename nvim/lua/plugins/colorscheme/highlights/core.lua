return function(c, opts)
  local bg = opts.transparent and "NONE" or c.base00

  return {
    -- UI
    Normal = { fg = c.base05, bg = bg },
    NormalFloat = { fg = c.base05, bg = c.base01 },
    FloatBorder = { fg = c.base02, bg = c.base01 },
    ColorColumn = { bg = c.base01 },
    CursorLine = { bg = c.base01 },
    LineNr = { fg = c.base03 },
    CursorLineNr = { fg = c.base0B, bold = true },
    Visual = { bg = c.base02 },
    Search = { fg = c.base00, bg = c.base0A },
    IncSearch = { fg = c.base00, bg = c.base09 },
    StatusLine = { fg = c.base04, bg = c.base01 },
    SignColumn = { bg = bg },
    MatchParen = { fg = c.base0C, bg = c.base02, bold = true },
    Whitespace = { fg = c.base02 },
    NonText = { fg = c.base02 },
    IblIndent = { fg = c.base02 }, 
    IblScope = { fg = c.base03 },

    -- STANDARD SYNTAX
    Comment = { fg = c.base03, italic = true },
    String = { fg = c.base0B },
    Character = { fg = c.base0B },
    Number = { fg = c.base09 },
    Float = { fg = c.base09 },
    Boolean = { fg = c.base09 },
    Identifier = { fg = c.base08 },
    Function = { fg = c.base0D },
    Statement = { fg = c.base0E },
    Conditional = { fg = c.base0E },
    Repeat = { fg = c.base0E },
    Label = { fg = c.base0E },
    Operator = { fg = c.base05 },
    Keyword = { fg = c.base0E },
    Exception = { fg = c.base08 },
    PreProc = { fg = c.base0A },
    Type = { fg = c.base0A },
    Special = { fg = c.base0C },
    Delimiter = { fg = c.base0F },

    -- TREESITTER (The Nix/Lua Fix)
    ["@variable"] = { fg = c.base05 },
    ["@variable.builtin"] = { fg = c.base08 },
    ["@variable.parameter"] = { fg = c.base08 },
    ["@variable.member"] = { fg = c.base08 }, -- Fixes Nix attributes
    ["@property"] = { fg = c.base08 },
    ["@field"] = { fg = c.base08 },
    ["@constant"] = { fg = c.base09 },
    ["@module"] = { fg = c.base0A },
    ["@string"] = { fg = c.base0B },
    ["@function"] = { fg = c.base0D },
    ["@function.call"] = { fg = c.base0D },
    ["@constructor"] = { fg = c.base0C },
    ["@keyword"] = { fg = c.base0E },
    ["@operator"] = { fg = c.base05 },
    ["@punctuation.delimiter"] = { fg = c.base0F },
    ["@punctuation.bracket"] = { fg = c.base05 },

    -- DIAGNOSTICS
    DiagnosticError = { fg = c.base08 },
    DiagnosticWarn = { fg = c.base0A },
    DiagnosticInfo = { fg = c.base0D },
    DiagnosticHint = { fg = c.base0C },
  }
end
