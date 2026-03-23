local is_nixos = vim.fn.executable("nixos-version") == 1

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  lazy = true,
  dependencies = {
    {
      "williamboman/mason-lspconfig.nvim",
      enabled = not is_nixos, -- prevents loading on NixOS
    },
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/lazydev.nvim", ft = "lua" },
  },
  config = function()
    -- import lspconfig plugin
    local lspconfig = require("lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    -- nixos checker
    local is_nixos = vim.fn.executable("nixos-version") == 1

    -- Capabilities for autocompletion
    local capabilities =
      vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), cmp_nvim_lsp.default_capabilities())

    -- Common on_attach function for all language servers
    local on_attach = function(client, bufnr)
      -- Key mappings and other setup can go here
      -- Example: vim.api.nvim_buf_set_keymap(bufnr, ...)
    end

    -- setup multiple lsp with same default options
    -- local servers = { "tsserver", "html", "cssls" }
    -- for _, lsp in ipairs(servers) do
    --   lspconfig["lsp"].setup {
    --     capabilities = capabilities,
    --     on_attach = on_attach,
    --   }
    -- end

    -- Setup diagnostic signs and diagnostics configuration
    local function setup_diagnostics()
      -- Configure diagnostic display options
      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.HINT] = "󰠠",
            [vim.diagnostic.severity.INFO] = "",
          },
        },
        underline = true,
        severity_sort = true,
        virtual_text = {
          prefix = "●",
          spacing = 2,
          severity = { min = vim.diagnostic.severity.HINT },
        },
        float = { border = "rounded", source = true, header = "", prefix = "" },
        update_in_insert = false,
      })
    end

    -- Call setup function immediately or from your config setup
    setup_diagnostics()

    -- show borders on hover
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
      border = "single",
      title = " Hover ",
    })

    -- server configs
    local servers = {
      lua_ls = {
        settings = { Lua = { diagnostics = { globals = { "vim" } }, completion = { callSnippet = "Replace" } } },
      },
      svelte = {
        on_attach = function(client, buf)
          vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = { "*.js", "*.ts" },
            callback = function(ctx)
              client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
            end,
          })
        end,
      },
      graphql = { filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" } },
      emmet_ls = {
        filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
      },
      -- Disables diagnostic refresh to stop the jsonls MethodNotFound error spam
      jsonls = {
        capabilities = (function()
          local cap = vim.deepcopy(capabilities)
          cap.workspace = cap.workspace or {}
          cap.workspace.diagnostics = cap.workspace.diagnostics or {}
          cap.workspace.diagnostics.refreshSupport = false
          return cap
        end)(),
      },
      -- TypeScript / JavaScript
      ts_ls = {
        init_options = {
          preferences = { disableSuggestions = false },
        },
      },
      -- zero-config servers
      nixd = {},
      pyright = {},
      bashls = {},
      cssls = {},
      html = {},
      tailwindcss = {},
      prismals = {},
      dockerls = {},
    }

    -- smart setup
    if is_nixos then
      -- NixOS natively maps the servers using packages in $PATH
      for server_name, config in pairs(servers) do
        config.capabilities = capabilities
        config.on_attach = config.on_attach or on_attach
        lspconfig[server_name].setup(config)
      end
    else
      -- Mason's handler
      local mason_lspconfig = require("mason-lspconfig")
      mason_lspconfig.setup_handlers({
        function(server_name)
          local config = servers[server_name] or {}
          config.capabilities = capabilities
          config.on_attach = config.on_attach or on_attach
          lspconfig[server_name].setup(config)
        end,
      })
    end
  end,
}
