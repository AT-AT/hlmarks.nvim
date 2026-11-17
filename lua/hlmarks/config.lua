-- =================================================================================================
--  Loaded Module
-- =================================================================================================

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

---@type color_spec
---
local DEFAULT_HL = {
  ctermfg = 255,
  ctermbg = 39,
  fg = '#eeeeee',
  bg = '#00afff',
  bold = true,
}

---@type string
---
M.plugin_name = 'Hlmarks'

---@type PluginOptions
---
M.default_options = {
  [const.SIGN_TYPE.BUFFER_MARK] = {
    highlight = {
      sign_hl = DEFAULT_HL,
      number_hl = DEFAULT_HL,
      line_hl = DEFAULT_HL,
    },
    sign_format = '%m>',
  },
  [const.SIGN_TYPE.FILE_MARK] = {
    highlight = {
      sign_hl = DEFAULT_HL,
      number_hl = DEFAULT_HL,
      line_hl = DEFAULT_HL,
    },
    sign_format = '%m>',
  },
  priority = 100,
  sync_interval = 500,
  event_names = {},
  desc_header = '[[' .. M.plugin_name .. ']]: ',
}

---@type PluginOptions
---
M.options = vim.tbl_deep_extend('force', {}, M.default_options)


-- =================================================================================================
--  Function (API)
-- =================================================================================================

--- Merge the specified parameters.
---
---@param local_options PluginOptions?
---
function M.merge_options(local_options)
  local_options = local_options or {}
  M.options = vim.tbl_deep_extend('force', M.options, local_options)
end


-- =================================================================================================
--  Export
-- =================================================================================================

return M
