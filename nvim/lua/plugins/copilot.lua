return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        -- Disable standard inline suggestions because we will route them through nvim-cmp
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
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
