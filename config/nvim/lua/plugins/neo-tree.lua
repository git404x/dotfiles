return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    -- setup neo-tree.nvim
    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "<leader>ee", ":Neotree source=filesystem toggle position=left<CR>", { desc = "Toggle file explorer" }) -- toggle file explorer
  end,
}
