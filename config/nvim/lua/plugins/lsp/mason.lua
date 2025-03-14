return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "neovim/nvim-lspconfig",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    -- import mason_tool_installer
    local mason_tool_installer = require("mason-tool-installer")

    -- mason keymap
    vim.keymap.set("n", "<leader>ms", ":Mason<CR>", { desc = "open mason" })
    vim.keymap.set("n", "<leader>ml", ":MasonLog<CR>", { desc = "open mason logs" })

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      -- list of servers for mason to install
      ensure_installed = {
        "cssls",
        "emmet_ls",
        "graphql",
        "html",
        "lua_ls",
        "prismals",
        "pyright",
        "svelte",
        "tailwindcss",
        "ts_ls",
      },
    })

    mason_tool_installer.setup({
      ensure_installed = {
        "black", -- python formatter
        "eslint_d", -- js linter
        "isort", -- python formatter
        "prettier", -- prettier formatter
        "pylint", -- python linter
        "stylua", -- lua formatter
      },
    })
  end,
}
