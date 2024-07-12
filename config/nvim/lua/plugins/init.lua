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
}
