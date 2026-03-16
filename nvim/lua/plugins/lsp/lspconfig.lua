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
    { "folke/neodev.nvim", opts = {} },
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

    -- Broadcast advanced folding capabilities for nvim-ufo
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }

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
      -- Define diagnostic signs with icons for the sign column (gutter)
      local signs = {
        Error = "",
        Warn = "",
        Hint = "󰠠",
        Info = "",
      }
      local sign_definitions = {}
      for type, icon in pairs(signs) do
        sign_definitions["DiagnosticSign" .. type] = { text = icon, texthl = "DiagnosticSign" .. type }
      end

      -- Configure diagnostic display options
      vim.diagnostic.config({
        signs = sign_definitions, -- Show signs with custom icons
        underline = true, -- Underline problematic code
        severity_sort = true, -- Sort diagnostics by severity
        virtual_text = { -- Virtual text with prefix icon and spacing
          prefix = "●",
          spacing = 2,
          severity = { min = vim.diagnostic.severity.HINT },
        },
        float = { -- Floating window options for show_line_diagnostics()
          border = "rounded",
          source = "always", -- Show source of diagnostic
          header = "",
          prefix = "",
        },
        update_in_insert = false, -- Update diagnostics while in insert mode (false for minimal distractions)
      })
    end

    -- Call setup function immediately or from your config setup
    setup_diagnostics()

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
      -- zero-config servers
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
