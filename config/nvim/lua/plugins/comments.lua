return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  config = function()
    local ctx_module = "ts_context_commentstring"

    -- prevent nil language_tree crashes
    require(ctx_module).setup({
      enable_autocmd = false,
    })

    -- setup & inject the AST hook
    require("Comment").setup({
      -- for commenting mixed-language files(tsx, jsx, svelte, html)
      pre_hook = require(ctx_module .. ".integrations.comment_nvim").create_pre_hook(),
    })
  end,
}
