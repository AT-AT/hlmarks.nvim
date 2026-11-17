-- =================================================================================================
--  Types
-- =================================================================================================

-- https://github.com/LuaLS/lua-language-server/discussions/1436#discussioncomment-3318346
---@class PluginOptions
---@field priority integer
---@field sync_interval integer
---@field event_names string[]
---@field desc_header string

---@alias color_spec table<string, any> Options acceptable to vim.api.nvim_set_hl()

---@alias mark_cache string as mark (a-zA-Z) + row-number ..., e.g., "b2e15"
---@alias mark_data table<string, mark_pos>
---@alias mark_pos { buffer: integer, row: integer }
---@alias mark_snapshot { cache: mark_cache, data: mark_data }
---@alias mark_spec { first: integer, last: integer, pattern: string }

---@alias sign_data table<string, sign_pos>
---@alias sign_pos { id: integer, row: integer }
