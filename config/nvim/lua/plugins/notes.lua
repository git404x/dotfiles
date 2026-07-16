return {
  -- Native Emacs Org-Mode Subsystem
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      require("orgmode").setup({
        org_agenda_files = { "~/notes/org/**/*" },
        org_default_notes_file = "~/notes/org/refile.org",
        org_capture_templates = {
          t = { description = "Task Boilerplate", template = "* TODO %?\n  %u" },
          n = { description = "Note Template", template = "* %?\n  %u" },
        },
      })
    end,
  },

  -- In-Terminal Side-by-Side Spatial Document Split Engine
  {
    "delphinus/md-render.nvim",
    ft = { "markdown" },
  },

  -- Visual Inline AST Transformation Layout
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "org" },
    dependencies = { "echasnovski/mini.icons" },
    config = function()
      require("render-markdown").setup({
        enabled = false,
        file_types = { "markdown", "org" },
        anti_conceal = { enabled = true },
      })

      -- Stateful viewport handler for split toggling
      local function toggle_md_preview()
        local found_win = nil
        local current_tab = vim.api.nvim_get_current_tabpage()

        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(current_tab)) do
          if vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if vim.bo[buf].filetype == "md-render" or buf_name:match("md%-render") then
              found_win = win
              break
            end
          end
        end

        if found_win then
          vim.api.nvim_win_close(found_win, true)
        else
          vim.cmd("vert MdRender split")
        end
      end

      -- Asynchronous Document Compiler
      local function export_document_picker()
        local file_ext = vim.fn.expand("%:e")
        local items = {}

        if file_ext == "md" or file_ext == "markdown" then
          items = { "PDF via Typst", "Standalone HTML Page" }
        elseif file_ext == "org" then
          items = { "PDF via Typst", "Standalone HTML Page" }
        else
          return
        end

        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local themes = require("telescope.themes")

        local mini_dropdown = themes.get_dropdown({
          previewer = false,
          shorten_path = false,
          layout_config = { width = 0.35, height = 0.30 },
        })

        -- Secondary execution pass: queries system font resources dynamically
        local function select_font_and_compile(strategy_selection)
          local current_file = vim.fn.expand("%:p")
          local output_file = vim.fn.expand("%:p:r")

          -- Subprocess worker execution block
          local function run_compiler_job(target_font)
            local cmd = {
              "pandoc",
              current_file,
              "--pdf-engine=typst",
              "-V",
              "mainfont=" .. target_font,
              "-o",
              output_file .. ".pdf",
            }
            vim.notify(
              "Compiling document with font: '" .. target_font .. "'...",
              vim.log.levels.INFO,
              { title = "Compiler Toolkit" }
            )

            local stderr_chunks = {}
            vim.fn.jobstart(cmd, {
              on_stderr = function(_, data)
                if data then
                  for _, line in ipairs(data) do
                    if line ~= "" then
                      table.insert(stderr_chunks, line)
                    end
                  end
                end
              end,
              on_exit = function(_, exit_code)
                if exit_code == 0 then
                  vim.notify("Compilation complete.", vim.log.levels.INFO, { title = "Compiler Toolkit" })
                else
                  local err_msg = table.concat(stderr_chunks, "\n")
                  if err_msg == "" then
                    err_msg = "Unknown compilation fault encountered."
                  end
                  vim.notify("Compilation failure:\n" .. err_msg, vim.log.levels.ERROR, { title = "Compiler Toolkit" })
                end
              end,
            })
          end

          -- Query system font layouts via Typst core engine wrapper
          local font_list = {}
          if vim.fn.executable("typst") == 1 then
            local raw_fonts = vim.fn.systemlist("typst fonts")
            local seen = {}
            for _, line in ipairs(raw_fonts) do
              local clean_name = line:match("^%s*(.-)%s*$")
              if clean_name and clean_name ~= "" and not seen[clean_name] then
                seen[clean_name] = true
                table.insert(font_list, clean_name)
              end
            end
            table.sort(font_list)
          end

          -- Fallback list if the command fails or returns empty
          if #font_list == 0 then
            font_list = { "Liberation Sans", "Liberation Serif", "DejaVu Sans", "Arial", "Helvetica" }
          end

          -- Spawn the compact font picker window block
          local font_dropdown = themes.get_dropdown({
            previewer = false,
            layout_config = { width = 0.45, height = 0.30 },
          })

          pickers
            .new(font_dropdown, {
              prompt_title = "Select Typography",
              finder = finders.new_table({ results = font_list }),
              sorter = conf.generic_sorter({}),
              attach_mappings = function(font_bufnr, _)
                actions.select_default:replace(function()
                  actions.close(font_bufnr)
                  local selected_font = action_state.get_selected_entry()[1]
                  run_compiler_job(selected_font)
                end)
                return true
              end,
            })
            :find()
        end

        -- Main strategy picker execution pass
        pickers
          .new(mini_dropdown, {
            prompt_title = "Select Output Document",
            finder = finders.new_table({ results = items }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, _)
              actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()[1]
                local current_file = vim.fn.expand("%:p")
                local output_file = vim.fn.expand("%:p:r")

                if selection == "PDF via Typst" then
                  -- Cascade directly to our dynamic typography picker pass
                  select_font_and_compile(selection)
                elseif selection == "Standalone HTML Page" then
                  if vim.fn.executable("pandoc") == 0 then
                    vim.notify(
                      "Compilation halted. 'pandoc' utility is missing from $PATH.",
                      vim.log.levels.ERROR,
                      { title = "Compiler Toolkit" }
                    )
                    return
                  end
                  local cmd = { "pandoc", current_file, "-o", output_file .. ".html" }
                  vim.fn.jobstart(cmd, {
                    on_exit = function(_, code)
                      if code == 0 then
                        vim.notify(
                          "HTML synchronization complete.",
                          vim.log.levels.INFO,
                          { title = "Compiler Toolkit" }
                        )
                      end
                    end,
                  })
                end
              end)
              return true
            end,
          })
          :find()
      end

      -- Mount buffer-local maps and background hooks during buffer file initialization
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("DocumentToolkitSettings", { clear = true }),
        pattern = { "markdown", "org" },
        callback = function(ev)
          vim.keymap.set(
            "n",
            "<leader>nv",
            toggle_md_preview,
            { buffer = ev.buf, silent = true, desc = "Toggle Markdown side-preview" }
          )
          vim.keymap.set(
            "n",
            "<leader>ne",
            export_document_picker,
            { buffer = ev.buf, silent = true, desc = "Export Note via Telescope" }
          )
          vim.keymap.set(
            "n",
            "<leader>nt",
            "<cmd>RenderMarkdown toggle<CR>",
            { buffer = ev.buf, silent = true, desc = "Toggle rich text visualization" }
          )

          -- Structural Snippet Injections
          local luasnip = require("luasnip")
          if ev.match == "markdown" then
            luasnip.add_snippets("markdown", {
              luasnip.s("doc_meta", {
                luasnip.t({ "---", 'title: "' }),
                luasnip.i(1, "Document Title"),
                luasnip.t({ '"', 'author: "' }),
                luasnip.i(2, "Author Name"),
                luasnip.t({ '"', 'date: "' }),
                luasnip.i(3, "YYYY-MM-DD"),
                luasnip.t({ '"', "---", "", "# " }),
                luasnip.i(0),
              }),
            })
          elseif ev.match == "org" then
            luasnip.add_snippets("org", {
              luasnip.s("org_meta", {
                luasnip.t({ "#+TITLE: " }),
                luasnip.i(1, "Notebook Title"),
                luasnip.t({ "", "#+AUTHOR: " }),
                luasnip.i(2, "Author Name"),
                luasnip.t({ "", "#+DATE: " }),
                luasnip.i(3, "Date Parameter"),
                luasnip.t({ "", "", "* TODO " }),
                luasnip.i(0),
              }),
            })
          end
        end,
      })
    end,
  },
}
