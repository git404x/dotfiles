-- session restore opts
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- cache core API structures
local api = vim.api
local fn = vim.fn
local log = vim.log

-- rocks_config
-- local lazy = require("lazy")
-- lazy.setup({
--   rocks = {
--     enabled = false,  -- Disable LuaRocks
--     hererocks = false -- Disable HereRocks
--   },
--   -- opts.rocks.hererocks = false
--   -- opts.rocks.enabled = false
-- })

-- GRACEFUL MEDIA HANDLER
local function open_in_external_app(file)
  -- Use vim.uv for Neovim 0.10+, fallback to vim.loop for older versions
  local uv = vim.uv or vim.loop
  local sysname = uv.os_uname().sysname
  local cmd

  if sysname == "Windows_NT" then
    cmd = { "cmd.exe", "/c", "start", '""', file }
  elseif sysname == "Darwin" then
    cmd = { "open", file }
  else
    cmd = { "xdg-open", file } -- Standard Linux
  end

  vim.fn.jobstart(cmd, { detach = true })
end

local binary_patterns = {
  -- Images
  "*.png",
  "*.jpg",
  "*.jpeg",
  "*.gif",
  "*.webp",
  "*.ico",
  "*.bmp",
  "*.tiff",
  "*.svg",
  -- Video & Audio
  "*.mp4",
  "*.mkv",
  "*.avi",
  "*.webm",
  "*.mov",
  "*.mp3",
  "*.wav",
  "*.flac",
  "*.ogg",
  -- Archives & Compression
  "*.zip",
  "*.tar",
  "*.tar.gz",
  "*.tgz",
  "*.rar",
  "*.7z",
  "*.xz",
  "*.bz2",
  "*.iso",
  "*.apk",
  "*.deb",
  "*.rpm",
  -- Documents
  "*.pdf",
  "*.epub",
  "*.mobi",
  "*.docx",
  "*.xlsx",
  "*.pptx",
  -- Executables & Binaries
  "*.exe",
  "*.dll",
  "*.so",
  "*.dylib",
  "*.bin",
  "*.sqlite",
  "*.db",
}

api.nvim_create_autocmd("BufReadCmd", {
  pattern = binary_patterns,
  callback = function(ctx)
    -- Fire the file to the OS
    open_in_external_app(ctx.file)

    -- Cleanly notify the user
    vim.notify("Opened " .. fn.fnamemodify(ctx.file, ":t") .. " in external viewer.", log.levels.INFO)

    -- Erase the buffer so garbage data never touches the screen
    api.nvim_schedule(function()
      pcall(api.nvim_buf_delete, ctx.buf, { force = true })
    end)
  end,
})

-- LspLog command
api.nvim_create_user_command("LspLog", function()
  local log_path = vim.lsp.log.get_filename()
  if fn.filereadable(log_path) == 1 then
    vim.cmd("edit " .. log_path)
  else
    vim.notify("LSP log is empty or does not exist.", log.levels.WARN)
  end
end, { desc = "Open the active LSP log file" })
