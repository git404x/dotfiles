return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  event = { "BufReadPost" },
  cmd = { "Telescope", "TodoTelescope" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
    {
      "nvim-telescope/telescope-ui-select.nvim",
      event = { "VeryLazy" },
    },
  },

  config = function()
    -- Setup telescope.nvim
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local telescope_themes = require("telescope.themes")
    local builtin = require("telescope.builtin")

    telescope.setup({
      defaults = {
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
            ["<C-j>"] = actions.move_selection_next, -- move to next result
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          },
        },
      },
      extensions = {
        ["ui-select"] = {
          telescope_themes.get_dropdown({
            -- even more opts
          }),
        },
      },
    })

    -- To get ui-select loaded and working with telescope, you need to call
    -- load_extension, somewhere after setup function:

    -- List of extensions to load
    local extensions = { "fzf", "ui-select" }

    -- Load each extension sequentially
    for _, extension in ipairs(extensions) do
      telescope.load_extension(extension)
    end

    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
    -- keymap.set("n", "<leader>ff", builtin.find_files)
    keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
    keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
    -- keymap.set("n", "<leader>fg", builtin.live_grep)
    keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
    keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })

    keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "display a list of available help tags" })
    -- keymap.set("n", "<leader>fh", builtin.help_tags)

    -- buffer picker
    keymap.set("n", "<leader>fb", function()
      builtin.buffers({
        initial_mode = "normal",
      })
    end)
  end,
}
