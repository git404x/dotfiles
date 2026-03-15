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
  -- init() runs BEFORE the plugin is loaded. This catches startup spam perfectly.
  init = function()
    local orig_notify = vim.notify

    vim.notify = function(msg, level, opts)
      -- fix the annoying lspconfig warning
      if type(msg) == "string" and msg:match("require%('lspconfig'%).*is deprecated") then
        return -- silence warn
      end

      -- load nvim-notify.
      local has_notify, notify = pcall(require, "notify")
      if has_notify then
        notify(msg, level, opts)
      else
        -- Fallback to default if notify hasn't loaded yet
        orig_notify(msg, level, opts)
      end
    end
  end,
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

    -- We do NOT set `vim.notify = notify` here because we want our
    -- custom spam-filter in options.lua to intercept the messages first!
  end,
}
