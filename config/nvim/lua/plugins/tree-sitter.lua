return {
  {
    "romus204/tree-sitter-manager.nvim",
    config = function()
      require("tree-sitter-manager").setup({
        ensure_installed = {
          "bash",
          "nix",
          "css",
          "dockerfile",
          "gitignore",
          "graphql",
          "html",
          "javascript",
          "json",
          "prisma",
          "svelte",
          "tsx",
          "typescript",
          "yaml",
        },

        auto_install = true,

        noauto_install = {
          "c",
          "lua",
          "markdown",
          "markdown_inline",
          "query",
          "vim",
          "vimdoc",
        },

        -- native treesitter highlighting is active globally
        highlight = true,

        -- ui
        nerdfont = true,
        border = "rounded",
      })
    end,
  },

  -- Standalone Autotag
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },
}
