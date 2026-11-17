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

---@module 'hlmarks.mark'
---
local mark = require('hlmarks.mark')

---@module 'hlmarks.sign'
---
local sign = require('hlmarks.sign')


-- =================================================================================================
--  Namespace
-- =================================================================================================

local M = {}


-- =================================================================================================
--  Definition
-- =================================================================================================

---@type uv.uv_timer_t?
---
local sync_timer = nil

---@type integer
---
local AUTOCMD_GROUP_ID = api.nvim_create_augroup(config.plugin_name .. 'AutoCmd', {})


-- =================================================================================================
--  Function (API)
-- =================================================================================================

--- Setup.
---
---@param local_options PluginOptions?
---
function M.setup(local_options)
  config.merge_options(local_options or {})
  sign.setup()
  M.define_watcher()
  M.define_timer()
  M.define_listener()
  M.override_keymap()
end

-- -------------------------------------------------------------------------------------------------

--- Remove all marks in the current buffer.
---
function M.remove_all()
  mark.remove_all()
  M.sync(api.nvim_get_current_buf())
end

--- Remove marks at the current row.
---
function M.remove_on_line()
  mark.remove_on_line()
  M.sync(api.nvim_get_current_buf())
end

--- Toggle a mark.
---
function M.set_mark(mark_name)
  mark.toggle(mark_name)
  M.sync(api.nvim_get_current_buf())
end

--- Set an unused buffer mark.
---
function M.set_next_buffer_mark()
  local next_mark = mark.next_local()

  if next_mark then
    mark.toggle(next_mark)
    M.sync(api.nvim_get_current_buf())
  end
end

--- Set an unused global mark.
---
function M.set_next_file_mark()
  local next_mark = mark.next_global()

  if next_mark then
    mark.toggle(next_mark)
    M.sync(api.nvim_get_current_buf())
  end
end

--- Synchronize.
---
---@param buf_id integer
---
function M.sync(buf_id)
  local data = mark.data_if_changed(buf_id)

  if data ~= nil then
    sign.sync(buf_id, data)
    mark.cache(buf_id)
  end
end


-- =================================================================================================
--  Function (Helper)
-- =================================================================================================

--- Define a listener for external events.
---
---@private
---
function M.define_listener()
  local event_names = config.options.event_names

  if vim.tbl_count(event_names) <= 0 then
    return
  end

  api.nvim_create_autocmd('User', {
    pattern = event_names,
    callback = function(ev)
      local data = ev.data

      M.sync(data.buf_id)
    end,
  })
end

--- Register a timer for executing synchronization processing.
---
---@private
---
--- Note: Refer to the section on synchronization in the document.
---
function M.define_timer()
  if sync_timer then
    return
  end

  sync_timer = vim.uv.new_timer()

  if sync_timer then
    sync_timer:start(500, config.options.sync_interval, vim.schedule_wrap(function()
      local buffers = M.visible_buffers()

      for _, buf_id in ipairs(buffers) do
        M.sync(buf_id)
      end
    end))
  end
end

--- Register autocmds for executing synchronization processes.
---
---@private
---
--- Note: Refer to the section on synchronization in the document.
---
function M.define_watcher()
  api.nvim_create_autocmd('BufEnter', {
    group = AUTOCMD_GROUP_ID,
    callback = function(ev)
      M.sync(ev.buf)
    end,
  })

  api.nvim_create_autocmd('TabEnter', {
    group = AUTOCMD_GROUP_ID,
    callback = function()
      local buffers = M.visible_buffers()

      for _, buf_id in ipairs(buffers) do
        M.sync(buf_id)
      end
    end,
  })
end

--- Override the key mappings for `m[a-zA-Z]` commands.
---
---@private
---
--- Note:
---   - The approach of remapping the `m` command itself was not adopted for the following reasons:
---     - It would require logic to distinguish characters other than `a-zA-Z`, as well as branching
---       between plugin functionality and native commands.
---     - Since this process occurs only when the plugin is loaded, the performance overhead is not
---       a concern.
---
function M.override_keymap()
  for _, range in ipairs({
    { const.MARK_SPEC.LOCAL.first, const.MARK_SPEC.LOCAL.last },
    { const.MARK_SPEC.GLOBAL.first, const.MARK_SPEC.GLOBAL.last },
  }) do
    for code = range[1], range[2] do
      local mark_name = string.char(code)

      vim.keymap.set('n', 'm' .. mark_name, function()
        M.set_mark(mark_name)
      end, {
        desc = config.options.desc_header .. 'Set mark ' .. mark_name,
      })
    end
  end
end

--- Retrieve the IDs of all active buffers within the current tab.
---
---@private
---@return integer[]
---
function M.visible_buffers()
  local tab_id = api.nvim_get_current_tabpage()
  local win_ids = api.nvim_tabpage_list_wins(tab_id)
  local buffers = {}

  for _, win_id in ipairs(win_ids) do
    -- Exclude floating windows.
    if api.nvim_win_get_config(win_id).relative == '' then

      local buf_id = api.nvim_win_get_buf(win_id)

      -- By design, any buffer displayed in a window is guaranteed to be loaded; therefore, the
      -- check using `nvim_buf_is_loaded()` can be omitted.
      buffers[buf_id] = true
    end
  end

  return vim.tbl_keys(buffers)
end


-- =================================================================================================
--  Export
-- =================================================================================================

return {
  remove_all = M.remove_all,
  remove_on_line = M.remove_on_line,
  set_mark = M.set_mark,
  set_next_buffer_mark = M.set_next_buffer_mark,
  set_next_file_mark = M.set_next_file_mark,
  setup = M.setup,
  sync = M.sync,
}
