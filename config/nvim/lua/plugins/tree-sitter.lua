return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build= ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    -- import nvim-treesitter plugin
    local treesitter = require("nvim-treesitter.configs")

    -- configure treesitter
    treesitter.setup({
      highlight = { enable = true }, -- enable syntax highlighting
      indent = { enable = true }, -- enable indentation
      autotag = { enable = true }, -- enable autotagging (w/ nvim-ts-autotag plugin)

      -- ensure these language parsers are installed
      ensure_installed = {
        "lua",
        "vim",
        "json",
        "javascript",
        "typescript",
        "tsx",
        "yaml",
        "html",
        "css",
        "prisma",
        "markdown",
        "markdown_inline",
        "svelte",
        "graphql",
        "bash",
        "dockerfile",
        "gitignore",
        "query",
        "vimdoc",
        "c",
      },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },

    })
  end,
}
