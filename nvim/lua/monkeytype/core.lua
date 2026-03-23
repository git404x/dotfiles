local M = {}
local words = require("monkeytype.words")

-- State variables
M.buf = nil
M.ns = vim.api.nvim_create_namespace("monkeytype_ns")
M.target_text = ""
M.typed_text = ""

local function render()
  -- Clear previous highlights
  vim.api.nvim_buf_clear_namespace(M.buf, M.ns, 0, -1)

  local target_len = string.len(M.target_text)
  local typed_len = string.len(M.typed_text)

  -- Loop through what the user has typed so far
  for i = 1, target_len do
    local hl_group = "MonkeytypeUntyped"
    local char_target = string.sub(M.target_text, i, i)
    local char_typed = nil

    if i <= typed_len then
      char_typed = string.sub(M.typed_text, i, i)
      if char_typed == char_target then
        hl_group = "MonkeytypeTyped"
      else
        hl_group = "MonkeytypeMistake"
      end
    end

    -- Apply the color via Extmark for each character
    vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, i - 1, {
      end_col = i,
      hl_group = hl_group,
      priority = 100,
    })
  end

  -- Draw a fake cursor at the current typing position
  if typed_len < target_len then
    vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, typed_len, {
      end_col = typed_len + 1,
      hl_group = "MonkeytypeCursor",
      priority = 101,
    })
  end
end

local function handle_input(char)
  -- Stop if test is done
  if string.len(M.typed_text) >= string.len(M.target_text) then
    return
  end

  -- Append the character to our typed state
  M.typed_text = M.typed_text .. char
  render()
end

local function handle_backspace()
  if string.len(M.typed_text) > 0 then
    -- Remove the last character
    M.typed_text = string.sub(M.typed_text, 1, -2)
    render()
  end
end

function M.init_buffer_keymaps()
  -- Map all lowercase alphabet keys
  for i = 97, 122 do
    local char = string.char(i)
    vim.keymap.set("n", char, function()
      handle_input(char)
    end, { buffer = M.buf, nowait = true })
  end

  -- Map Space and Backspace
  vim.keymap.set("n", "<Space>", function()
    handle_input(" ")
  end, { buffer = M.buf, nowait = true })
  vim.keymap.set("n", "<BS>", handle_backspace, { buffer = M.buf, nowait = true })
end

function M.start_test(bufnr)
  M.buf = bufnr
  M.target_text = words.generate_test(15) -- Generate 15 words
  M.typed_text = ""

  -- Put the target text into the buffer
  vim.api.nvim_buf_set_option(M.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, { M.target_text })
  vim.api.nvim_buf_set_option(M.buf, "modifiable", false) -- Lock it down

  M.init_buffer_keymaps()
  render()
end

return M
