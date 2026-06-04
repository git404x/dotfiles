-- cmp source function
local function set_cmp_sources(enable_copilot)
  local cmp_ok, cmp = pcall(require, "cmp")
  if not cmp_ok then
    return
  end

  local sources = {
    { name = "path" },
    { name = "buffer" },
    { name = "luasnip" },
    { name = "nvim_lsp" },
  }

  if enable_copilot then
    table.insert(sources, 1, { name = "copilot", group_index = 2 })
  end

  cmp.setup.global({
    sources = cmp.config.sources(sources),
  })
end

-- toggle AI on demand
local function toggle_ai()
  local lazy_config = require("lazy.core.config")
  local is_loaded = lazy_config.plugins["copilot.lua"] and lazy_config.plugins["copilot.lua"]._.loaded

  if not is_loaded then
    vim.notify("Booting up AI ...", vim.log.levels.INFO, { title = "Copilot" })
    -- load the dependency tree
    require("lazy").load({ plugins = { "copilot.lua", "copilot-cmp", "CopilotChat.nvim" } })
    set_cmp_sources(true)
    vim.notify("AI Online.", vim.log.levels.INFO, { title = "Copilot" })
    vim.g.ai_is_active = true
  else
    -- toggle existing LSP client and node daemon natively
    if vim.g.ai_is_active then
      vim.notify("Stopping AI ...", vim.log.levels.WARN, { title = "Copilot" })
      require("copilot.command").disable()
      set_cmp_sources(false)
      vim.g.ai_is_active = false
    else
      vim.notify("Waking AI ...", vim.log.levels.INFO, { title = "Copilot" })
      require("copilot.command").enable()
      set_cmp_sources(true)
      vim.g.ai_is_active = true
    end
  end
end

-- Register the interactive command
vim.api.nvim_create_user_command("ToggleAI", toggle_ai, {})

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    keys = {
      { "<leader>ai", toggle_ai, desc = "Toggle AI Suite" },
    },
    config = function()
      require("copilot").setup({
        -- Disable standard inline suggestions because we will route them through nvim-cmp
        suggestion = { enabled = false },
        panel = { enabled = false },
        -- prevent 'should_attach' warns
        filetypes = {
          ["*"] = true,
        },
      })
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    lazy = true,
    dependencies = { "zbirenbaum/copilot.lua" },
    config = function()
      -- link copilot suggestion to string highlight
      vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { link = "String" })
      require("copilot_cmp").setup()
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    lazy = true,
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    opts = {
      debug = false,
      highlight_selection = false,
      window = {
        layout = "float",
        width = 0.8,
        height = 0.8,
        border = "rounded",
      },
    },
    keys = {
      {
        "<leader>cct",
        "<cmd>CopilotChatToggle<cr>",
        desc = "CopilotChat - Toggle",
      },
      {
        "<leader>cce",
        "<cmd>CopilotChatExplain<cr>",
        desc = "CopilotChat - Explain selected code",
      },
      {
        "<leader>ccr",
        "<cmd>CopilotChatReview<cr>",
        desc = "CopilotChat - Review selected code",
      },
      {
        "<leader>ccf",
        "<cmd>CopilotChatFix<cr>",
        desc = "CopilotChat - Fix code",
      },
    },
  },
}
