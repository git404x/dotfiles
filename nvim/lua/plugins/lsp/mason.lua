local is_nixos = vim.fn.executable("nixos-version") == 1

return {
  "williamboman/mason.nvim",
  enabled = not is_nixos, -- prevents Mason from loading on NixOS
  dependencies = {
    "williamboman/mason-lspconfig.nvim", -- Ensure this is loaded after mason
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "neovim/nvim-lspconfig", -- This will be loaded later
  },
  event = { "BufReadPre", "BufNewFile" },
  lazy = false,
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    -- import mason_tool_installer
    local mason_tool_installer = require("mason-tool-installer")

    local keymap = vim.keymap
    -- mason keymap
    keymap.set("n", "<leader>ms", ":Mason<CR>", { desc = "open mason" })
    keymap.set("n", "<leader>ml", ":MasonLog<CR>", { desc = "open mason logs" })

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
      -- list of language servers for mason to install
      ensure_installed = is_nixos and {} or {
        "ast_grep",
        "vimls",
        "dockerls",
        "pyright",
        "bashls",
        "fish_lsp",
        "jsonls",
        "cssls",
        "html",
        "hyprls",
        "prismals",
        "systemd_ls",
        "tailwindcss",
        "lua_ls",
        "awk_ls",
        "emmet_ls",
        "graphql",
      },
    })

    mason_tool_installer.setup({
      ensure_installed = is_nixos and {} or {
        -- formatters
        "nixfmt",
        "black",
        "isort",
        "prettier",
        "stylua",

        -- linters
        "eslint_d",
        "pylint",
      },
    })
  end,
}
