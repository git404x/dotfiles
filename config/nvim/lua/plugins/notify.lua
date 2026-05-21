return {
  "rcarriga/nvim-notify",
  event = "VeryLazy",
  keys = {
    {
      "<leader>un",
      function()
        require("notify").dismiss({ silent = true, pending = true })
      end,
      desc = "Dismiss all Notifications",
    },
  },
  config = function()
    local notify = require("notify")

    notify.setup({
      background_colour = "#050705", -- OLED black
      timeout = 3000, -- disappear after 3 seconds
      max_width = 60,
      max_height = 10,
      stages = "fade", -- Smooth fade-in/fade-out animation
      render = "wrapped-compact", -- Minimalist, sleek design
      top_down = true, -- spawn at the top right
    })
    vim.notify = notify
  end,
}
