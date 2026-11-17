-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@see vim.api
---
local api = vim.api

---@module 'hlmarks.config'
---
local config = require('hlmarks.config')

---@module 'hlmarks.const'
---
local const = require('hlmarks.const')


-- =================================================================================================
--  Namespace
-- =================================================================================================

local M = {}


-- =================================================================================================
--  Definition
-- =================================================================================================

---@type table<string, string>
---
local SNAKE_TO_CAMEL = {
  sign_hl = 'SignHl',
  number_hl = 'NumberHl',
  line_hl = 'LineHl',
  [const.SIGN_TYPE.BUFFER_MARK] = 'BufferMark',
  [const.SIGN_TYPE.FILE_MARK] = 'FileMark',
}

---@type integer
---
local NS = api.nvim_create_namespace(config.plugin_name)

---@type table<string, table>
---
local SIGN_SPEC = {
  -- Injected by precompile_sign_spec()
}


-- =================================================================================================
--  Function (API)
-- =================================================================================================

-- Note:
--  - The extmark is NEVER removed by ANY operation, with the exception of nvim_buf_del_extmark().
--  - The extmark coordinates are based on 0-0-indexed.

--- Setup.
---
function M.setup()
  M.define_highlight(const.SIGN_TYPE.BUFFER_MARK)
  M.define_highlight(const.SIGN_TYPE.FILE_MARK)
  M.prebuild_sign_spec()
end

-- -------------------------------------------------------------------------------------------------

--- Synchronize the sign with the mark.
---
---@param buf_id integer
---@param mark_data mark_data|{}
---
--- Note:
---   - Possible Operations:
---       Case                                  Note
---        (1) mark moved (ins/del row)          noop (auto-moved, deleted row has no marks)
---        (2) mark moved (re-mark)
---        (3) mark added
---        (4) mark removed (toggle)
---        (5) mark removed (on-line)
---        (6) mark removed (ex-command)         unable to sync manually
---        (7) mark removed (del marked row)     unable to sync manually
---        (8) mark removed (all in buffer)
---     (Refer to the section on synchronization in the document)
---
function M.sync(buf_id, mark_data)
  local signs = api.nvim_buf_get_extmarks(buf_id, NS, 0, -1, { details = true })
  local mark_count = vim.tbl_count(mark_data)
  local sign_count = vim.tbl_count(signs)

  if mark_count == 0 and sign_count == 0 then
    return
  end

  -- Case (8)
  if mark_count == 0 then
    api.nvim_buf_clear_namespace(buf_id, NS, 0, -1)

    return
  end

  local sign_data = M.to_data(signs)

  -- Case (4), (5), (6), (7), (P/T: (1))
  for sign, data in pairs(sign_data) do
    if mark_data[sign] == nil then
      api.nvim_buf_del_extmark(buf_id, NS, data.id)
    end
  end

  -- Case (2), (3) (P/T: (1))
  for mark, data in pairs(mark_data) do
    local expected_sign_row = data.row - 1

    if sign_data[mark] == nil or sign_data[mark].row ~= expected_sign_row then
      M.set(mark, buf_id, expected_sign_row)
    end
  end

  -- Case (1)
  -- noop
end


-- =================================================================================================
--  Function (Helper)
-- =================================================================================================

-- / Setup Process
-- -------------------------------------------------------------------------------------------------

--- Define the highlights.
---
---@private
---@param sign_type sign_type
---
function M.define_highlight(sign_type)
  local hl_group_prefix = config.plugin_name .. SNAKE_TO_CAMEL[sign_type]
  local color_specs = config.options[sign_type].highlight

  for hl_group_name, color_spec in pairs(color_specs) do
    local hl_group = hl_group_prefix .. SNAKE_TO_CAMEL[hl_group_name]

    api.nvim_set_hl(const.NVIM_API.GLOBAL_NS_ID, hl_group, color_spec)
  end
end

--- Pre-build the generation parameters for each sign type.
---
---@private
---
function M.prebuild_sign_spec()
  local plugin_name = config.plugin_name
  local buffer_mark, file_mark = const.SIGN_TYPE.BUFFER_MARK, const.SIGN_TYPE.FILE_MARK

  for _, sign_type in ipairs({ buffer_mark, file_mark }) do
    SIGN_SPEC[sign_type] = {
      hl_group = {
        sign_hl_group = plugin_name .. SNAKE_TO_CAMEL[sign_type] .. SNAKE_TO_CAMEL.sign_hl,
        line_hl_group = plugin_name .. SNAKE_TO_CAMEL[sign_type] .. SNAKE_TO_CAMEL.line_hl,
        number_hl_group= plugin_name .. SNAKE_TO_CAMEL[sign_type] .. SNAKE_TO_CAMEL.number_hl,
      },
      sign_format = config.options[sign_type].sign_format,
    }
  end
end

-- / Data Handling
-- -------------------------------------------------------------------------------------------------

--- Generate sign data from a sign list.
---
---@private
---@param signs vim.api.keyset.get_extmark_item[]
---@return sign_data|{}
---
--- Note:
---   - Sample return value for nvim_buf_get_extmarks():
---       { { 97, 6, 0, { -- id(=string.byte(mark)), row, col (0-0-indexed)
---         ns_id = 20,
---         line_hl_group = "...",
---         number_hl_group = "...",
---         sign_hl_group = "...",
---         priority = 100,
---         sign_text = "a>", -- 2-byte wide, be care!
---       } } }
---
function M.to_data(signs)
  local sign_data = {}

  for _, sign in ipairs(signs) do
    local name = string.char(sign[1])

    sign_data[name] = {
      id = sign[1],
      row = sign[2],
    }
  end

  return sign_data
end

-- / Sign Handling
-- -------------------------------------------------------------------------------------------------

--- Place a sign on the specified line in the current buffer.
---
---@private
---@param mark string
---@param buf_id integer
---@param row integer 0-0-indexed
---
function M.set(mark, buf_id, row)
  local sign_type = const.SIGN_TYPE.BUFFER_MARK

  if string.match(mark, const.MARK_SPEC.GLOBAL.pattern) then
    sign_type = const.SIGN_TYPE.FILE_MARK
  end

  local sign_spec = SIGN_SPEC[sign_type]
  local params = vim.tbl_extend('force', {
    id = string.byte(mark),
    sign_text = string.gsub(sign_spec.sign_format, '%%m', mark),
    right_gravity = false,
    priority = config.options.priority,
  }, sign_spec.hl_group)

  api.nvim_buf_set_extmark(buf_id, NS, row, 0, params)
end


-- =================================================================================================
--  Export
-- =================================================================================================

return M
