return {
  "nvim-base16-engine",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/colorscheme",
  lazy = false,
  priority = 1000,
  opts = {
    default_theme = "fruit_salad",
    transparent = false,
    telescope_borders = true,
    integrations = {
      cmp = true,
      telescope = true,
      gitsigns = true,
      bufferline = true,
      cokeline = true,
      lualine = true,
      nvimtree = true,
    },
  },
  config = function(_, opts)
    local cache_path = vim.fn.stdpath("data") .. "/theme_cache.json"

    local function get_themes()
      local dir = vim.fn.stdpath("config") .. "/lua/plugins/colorscheme/themes"
      local files, db = vim.fn.readdir(dir), {}
      for _, file in ipairs(files) do
        if file:match("%.lua$") then
          local mod = file:gsub("%.lua$", "")
          local ok, theme_mod = pcall(require, "plugins.colorscheme.themes." .. mod)
          if ok and type(theme_mod) == "table" then
            for _, t_data in pairs(theme_mod) do
              if t_data.name then
                db[t_data.name] = t_data
              end
            end
          end
        end
      end
      return db
    end

    _G.LoadTheme = function(theme_name, save)
      local themes = get_themes()
      local theme = themes[theme_name]
      if not theme then
        vim.notify("Theme Engine: Theme '" .. tostring(theme_name) .. "' not found.", vim.log.levels.ERROR)
        return
      end

      -- Wipe Defaults
      vim.cmd("hi clear")
      if vim.fn.exists("syntax_on") then
        vim.cmd("syntax reset")
      end
      vim.o.termguicolors = true
      vim.o.background = theme.polarity
      vim.g.colors_name = theme.name

      -- Apply Highlight Modules with Strict Error Handling
      local hl_modules = { "core" }
      for int, enabled in pairs(opts.integrations) do
        if enabled then
          table.insert(hl_modules, int)
        end
      end

      for _, mod in ipairs(hl_modules) do
        -- clear cache so switching themes doesn't bleed old highlight tables
        package.loaded["plugins.colorscheme.highlights." .. mod] = nil
        local ok, get_hls = pcall(require, "plugins.colorscheme.highlights." .. mod)

        if ok and type(get_hls) == "function" then
          local success, highlights = pcall(get_hls, theme.colors, opts)
          if success and type(highlights) == "table" then
            for group, hl_opts in pairs(highlights) do
              vim.api.nvim_set_hl(0, group, hl_opts)
            end
          else
            vim.notify("Theme Engine: highlight/" .. mod .. ".lua failed to return a table.", vim.log.levels.WARN)
          end
        else
          vim.notify(
            "Theme Engine: Missing or invalid highlight module -> highlights/" .. mod .. ".lua",
            vim.log.levels.WARN
          )
        end
      end

      -- Trigger Redraws for plugins like Lualine
      vim.api.nvim_exec_autocmds("ColorScheme", { pattern = theme.name })

      -- Save to Cache
      if save then
        local file = io.open(cache_path, "w")
        if file then
          file:write(vim.fn.json_encode({ name = theme_name }))
          file:close()
        end
      end
    end

    -- Boot Sequence
    local target = opts.default_theme
    local file = io.open(cache_path, "r")
    if file then
      local ok, parsed = pcall(vim.fn.json_decode, file:read("*a"))
      if ok and parsed.name then
        target = parsed.name
      end
      file:close()
    end
    _G.LoadTheme(target, false)

    -- Telescope Switcher
    vim.keymap.set("n", "<leader>th", function()
      local names = {}
      for n, _ in pairs(get_themes()) do
        table.insert(names, n)
      end
      table.sort(names)

      require("telescope.pickers")
        .new(require("telescope.themes").get_dropdown({ previewer = false }), {
          prompt_title = " 󰏘 Switch Theme ",
          finder = require("telescope.finders").new_table({ results = names }),
          sorter = require("telescope.config").values.generic_sorter({}),
          attach_mappings = function(prompt_bufnr)
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              _G.LoadTheme(action_state.get_selected_entry()[1], true)
            end)
            return true
          end,
        })
        :find()
    end, { desc = "Switch Theme" })
  end,
}
