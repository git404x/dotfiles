-- vim stuff
vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt -- for conciseness

-- color & highlight
vim.o.termguicolors = true
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes" -- signcolumn so text doesn't shift
opt.cursorline = true -- highlight the current cursor line

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.softtabstop = 2 -- 2 spaces for soft tabs
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one
opt.smartindent = true -- automatic indentation of code

-- line wrapping
opt.wrap = true -- soft wrap
opt.linebreak = true -- logical word boundary
opt.breakindent = true -- inherit the indentation
vim.g.visual_wrap_nav = true -- set to false, so j/k ignore visual wrap

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
opt.swapfile = false
opt.backup = false
opt.writebackup = false

-- Highlight search
opt.hlsearch = true
opt.incsearch = true
