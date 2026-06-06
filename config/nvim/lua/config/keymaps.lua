-- set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local keymap = vim.keymap -- for conciseness

-- General Keymaps -------------------

-- basic navigation
keymap.set("i", "<C-b>", "<ESC>^i", { desc = "Beginning of line" })
keymap.set("i", "<C-e>", "<End>", { desc = "End of line" })
keymap.set("i", "<C-h>", "<Left>", { desc = "Move left" })
keymap.set("i", "<C-l>", "<Right>", { desc = "Move right" })
keymap.set("i", "<C-j>", "<Down>", { desc = "Move down" })
keymap.set("i", "<C-k>", "<Up>", { desc = "Move up" })

-- Close Current Pane Easily
keymap.set("n", "<A-x>", ":bdelete<CR>")

-- exit insert mode or file
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode" })
keymap.set("n", "<leader>xx", ":q!<CR>", { desc = "Exit" })

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- delete single character without copying into register
-- keymap.set("n", "x", '"_x')

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>wv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>wh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>we", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>wx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

-- tab management
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- wrapping

-- -- soft wrap
keymap.set("n", "<leader>uw", function()
  vim.opt_local.wrap = not vim.opt_local.wrap:get()
  local state = vim.opt_local.wrap:get() and "ON" or "OFF"
  vim.notify("Soft Wrap " .. state, vim.log.levels.INFO, { title = "Text Engine" })
end, { desc = "Toggle soft (visual) line wrapping" })

-- hard wrap
keymap.set("n", "<leader>uh", function()
  if vim.bo.textwidth == 0 then
    -- calc window width minus gutters (numbers, folds, git signs)
    local win_width = vim.api.nvim_win_get_width(0)
    local gutter_margin = vim.opt.numberwidth:get() + 4
    local dynamic_tw = win_width - gutter_margin

    vim.bo.textwidth = dynamic_tw
    vim.opt_local.formatoptions:append("t")
    vim.notify("Hard Wrap ON (tw=" .. dynamic_tw .. ")", vim.log.levels.INFO, { title = "Text Engine" })
  else
    vim.bo.textwidth = 0
    vim.opt_local.formatoptions:remove("t")
    vim.notify("Hard Wrap OFF", vim.log.levels.WARN, { title = "Text Engine" })
  end
end, { desc = "Toggle dynamic hard line wrapping" })

-- -- falls back to standard absolute movement if count is provided.
keymap.set({ "n", "x" }, "j", function()
  return (vim.g.visual_wrap_nav and vim.v.count == 0) and "gj" or "j"
end, { expr = true, silent = true, desc = "Smart move down" })

keymap.set({ "n", "x" }, "k", function()
  return (vim.g.visual_wrap_nav and vim.v.count == 0) and "gk" or "k"
end, { expr = true, silent = true, desc = "Smart move up" })

keymap.set({ "n", "x" }, "0", function()
  return vim.g.visual_wrap_nav and "g0" or "0"
end, { expr = true, silent = true, desc = "Smart start of visual line" })

keymap.set({ "n", "x" }, "^", function()
  return vim.g.visual_wrap_nav and "g^" or "^"
end, { expr = true, silent = true, desc = "Smart first non-blank of visual line" })

keymap.set({ "n", "x" }, "$", function()
  return vim.g.visual_wrap_nav and "g$" or "$"
end, { expr = true, silent = true, desc = "Smart end of visual line" })

keymap.set({ "n", "x" }, "<Home>", function()
  return vim.g.visual_wrap_nav and "g<Home>" or "<Home>"
end, { expr = true, silent = true, desc = "Smart Home" })

keymap.set({ "n", "x" }, "<End>", function()
  return vim.g.visual_wrap_nav and "g<End>" or "<End>"
end, { expr = true, silent = true, desc = "Smart End" })
