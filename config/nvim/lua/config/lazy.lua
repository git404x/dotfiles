-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath
  })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- add your plugins inherits
    { import = "plugins" },
    { import = "plugins.lsp" }
  },
  -- automatically check for plugin updates
  checker = {
    enabled = true,
    notify = false,
  },
  -- Configure other settings
  change_detection = {
    notify = false,
  },
  ui = {
    icons = {
      ft = " ",
      lazy = "󰂠 ",
      loaded = " ",
      not_loaded = "󰄰 ",
    },
  },
})

-- lazy keymap
vim.keymap.set("n", "<leader>lz", ":Lazy<CR>", { desc = "Open Lazy pkg manager" })
