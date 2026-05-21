return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/monkeytype",
    name = "monkeytype.nvim",
    config = function()
      require("monkeytype").setup()
    end,
  },
}
