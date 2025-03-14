return {

  -- lua functions that many plugins use
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },

  -- tmux & split window navigation
  {
    "christoomey/vim-tmux-navigator",
  },

  -- open popup view for actions like rename in NvimTree
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
  },

  -- colorizer
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    config = true,
  },

  -- nvim-surround
  {
  "kylechui/nvim-surround",
  event = { "BufReadPre", "BufNewFile" },
  version = "*", -- Use for stability; omit to use `main` branch for the latest features
  config = true,
  },

  -- vim-maximizer
  {
    "szw/vim-maximizer",
    keys = {
      { "<leader>sm", "<cmd>MaximizerToggle<CR>", desc = "Maximize/Minimize a split" },
    },
  },
}
