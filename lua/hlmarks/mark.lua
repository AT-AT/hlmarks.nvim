-- =================================================================================================
--  Loaded Module
-- =================================================================================================

---@see vim.api
---
local api = vim.api

---@see vim.fn
---
local fn = vim.fn

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

---@type string
---
local CACHE_KEY = 'hlmarks-nvim-mark-cache'


-- =================================================================================================
--  Function (API)
-- =================================================================================================

--- Store the mark cache for the specified buffer.
---
---@param buf_id integer
---@return mark_data|{}
---
function M.cache(buf_id)
  local snapshot = M.generate_snapshot(buf_id)

  vim.b[buf_id][CACHE_KEY] = snapshot.cache

  return snapshot.data
end

--- Retrieve the mark data if has any changes.
---
---@param buf_id integer
---@return mark_data|nil
---
--- Note:
---   - Generating a diff against the cache is NOT performed here.
---     (Refer to the section on synchronization in the document)
---
function M.data_if_changed(buf_id)
  local cache = M.extract_cache(buf_id)
  local snapshot = M.generate_snapshot(buf_id)

  if cache == snapshot.cache then
    return nil
  end

  return snapshot.data
end

--- Select an unused global mark.
---
---@return string|nil
---
function M.next_global()
  return M.next_one(M.all_globals(), const.MARK_SPEC.GLOBAL)
end

--- Select an unused buffer mark in the current buffer.
---
---@return string|nil
---
function M.next_local()
  local buf_id = api.nvim_get_current_buf()

  return M.next_one(M.locals(buf_id), const.MARK_SPEC.LOCAL)
end

--- Remove all marks in the current buffer.
---
function M.remove_all()
  M.remove_with(nil, const.MARK_SPEC.LOCAL)
  M.remove_with(nil, const.MARK_SPEC.GLOBAL)
end

--- Remove marks at the current row.
---
function M.remove_on_line()
  local row, _ = unpack(api.nvim_win_get_cursor(const.NVIM_API.CURRENT_WIN_ID))

  M.remove_with(row, const.MARK_SPEC.LOCAL)
  M.remove_with(row, const.MARK_SPEC.GLOBAL)
end

--- Toggle a mark at the current line.
---
---@param mark string
---
function M.toggle(mark)
  local buf_id = api.nvim_get_current_buf()
  local row, col = unpack(api.nvim_win_get_cursor(const.NVIM_API.CURRENT_WIN_ID))
  local mark_row, _ = unpack(api.nvim_buf_get_mark(buf_id, mark))

  if row == mark_row then
    M.remove(mark)
  else
    api.nvim_buf_set_mark(buf_id, mark, row, col, {})
  end
end


-- =================================================================================================
--  Function (Helper)
-- =================================================================================================

-- / Cache Handling
-- -------------------------------------------------------------------------------------------------

--- Build a cache string.
---
---@private
---@param ... mark_cache
---@return mark_cache
---
function M.build_cache(...)
  return table.concat({ ... }, '')
end

--- Extract the mark cache from the specified buffer.
---
---@private
---@param buf_id integer
---@return mark_cache
---
function M.extract_cache(buf_id)
  local cache = vim.b[buf_id][CACHE_KEY]

  if cache == nil then
    return ''
  end

  return cache
end

--- Generate a snapshot of marks in the specified buffer.
---
---@private
---@param buf_id integer
---@return mark_snapshot
---
function M.generate_snapshot(buf_id)
  local locals = M.locals(buf_id)
  local globals = M.globals(buf_id)
  local locals_cache = M.to_cache(locals, const.MARK_SPEC.LOCAL)
  local globals_cache = M.to_cache(globals, const.MARK_SPEC.GLOBAL)

  return {
    cache = M.build_cache(locals_cache, globals_cache),
    data = vim.tbl_extend('force', locals, globals),
  }
end

--- Generate a strings for caching.
---
---@private
---@param data mark_data|{}
---@param spec mark_spec
---@return mark_cache
---
function M.to_cache(data, spec)
  if vim.tbl_count(data) == 0 then
    return ''
  end

  local cache = {}

  for code = spec.first, spec.last do
    local mark_name = string.char(code)
    local mark_pos = data[mark_name]

    if mark_pos then
      cache[#cache + 1] = mark_name .. tostring(mark_pos.row)
    end
  end

  return table.concat(cache, '')
end

-- / Data Handling
-- -------------------------------------------------------------------------------------------------

--- Get data for global marks on all buffers.
---
---@private
---@return mark_data|{}
---
function M.all_globals()
  local marks = fn.getmarklist()

  return M.to_data(marks, nil, const.MARK_SPEC.GLOBAL.pattern)
end

--- Get data for local marks in the specified buffer.
---
---@private
---@param buf_id integer
---@return mark_data|{}
---
function M.locals(buf_id)
  local marks = fn.getmarklist(buf_id)

  return M.to_data(marks, buf_id, const.MARK_SPEC.LOCAL.pattern)
end

--- Get data for global marks in the specified buffer only.
---
---@private
---@param buf_id integer
---@return mark_data|{}
---
function M.globals(buf_id)
  local marks = fn.getmarklist()

  return M.to_data(marks, buf_id, const.MARK_SPEC.GLOBAL.pattern)
end

--- Generate mark data matching a specified buffer/pattern from a mark list.
---
---@private
---@param marks vim.fn.getmarklist.ret.item[]
---@param buf_id integer|nil All buffers are included if nil
---@param pattern string
---@return mark_data|{}
---
--- Note:
---   - Sample return value for Vim function getmarklist():
---       { {
---         mark = "'a",
---         pos = { 5, 16, 1, 0 }
---       }, ... }
---
function M.to_data(marks, buf_id, pattern)
  local mark_data = {}

  for _, mark in ipairs(marks) do
    local name = string.sub(mark.mark, 2)
    local buf_id_matched = false

    if (buf_id == nil) or (mark.pos[1] == buf_id) then
      buf_id_matched = true
    end

    if #name == 1 and string.match(name, pattern) and buf_id_matched then
      mark_data[name] = {
        buffer = mark.pos[1],
        row = mark.pos[2],
      }
    end
  end

  return mark_data
end

-- / Mark Handling
-- -------------------------------------------------------------------------------------------------

--- Select an unused mark.
---
---@private
---@param data mark_data|{}
---@param spec mark_spec
---@return string|nil
---
function M.next_one(data, spec)
  for code = spec.first, spec.last do
    local mark_name = string.char(code)

    if data[mark_name] == nil then
      return mark_name
    end
  end

  api.nvim_echo({ { 'Used up all marks!' } }, true, { err = true })
  vim.notify('Used up all marks!', vim.log.levels.ERROR)

  return nil
end

--- Remove a mark in the current buffer.
---
---@private
---@param mark string
---
--- Note: The only target required is the current buffer.
---
function M.remove(mark)
  -- By setting `row=0` in `nvim_buf_set_mark()`, it is possible to remove most types of marks,
  -- including both local and global marks.
  -- No error occurs even if the specified mark does not exist.
  -- BE CARE, global marks are removed REGARDLESS OF THE BUFFER NUMBER SPECIFIED.
  api.nvim_buf_set_mark(const.NVIM_API.CURRENT_BUF_ID, mark, 0, 0, {})
end

--- Remove the marks according to the parameters.
---
---@private
---@param row integer|nil If unspecified or nil, all marks in the current buffer are removed.
---@param spec mark_spec
---
--- Note: The only target required is the current buffer.
---
function M.remove_with(row, spec)
  for code = spec.first, spec.last do
    local mark_name = string.char(code)
    local mark_row, _ = unpack(api.nvim_buf_get_mark(const.NVIM_API.CURRENT_BUF_ID, mark_name))

    -- If no 'row' is specified, ensure that a mark exists -- as it is required for the global mark.
    -- (See the note within remove())
    if (row == nil and mark_row > 0) or (row ~= nil and row > 0 and mark_row == row) then
      M.remove(mark_name)
    end
  end
end


-- =================================================================================================
--  Export
-- =================================================================================================

return M
