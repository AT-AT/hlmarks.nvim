-- =================================================================================================
--  Definition
-- =================================================================================================

---@type table<string, integer>
---
local NVIM_API = {
  CURRENT_BUF_ID = 0,
  CURRENT_WIN_ID = 0,
  GLOBAL_NS_ID = 0,
}

---@type { GLOBAL: mark_spec, LOCAL: mark_spec }
---
local MARK_SPEC = {
  GLOBAL = {
    first = string.byte('A'),
    last = string.byte('Z'),
    pattern = '^[A-Z]$',
  },

  LOCAL = {
    first = string.byte('a'),
    last = string.byte('z'),
    pattern = '^[a-z]$',
  },
}

---@enum sign_type
---
local SIGN_TYPE = {
  BUFFER_MARK = 'buffer_mark',
  FILE_MARK = 'file_mark',
}


-- =================================================================================================
--  Export
-- =================================================================================================

return {
  NVIM_API = NVIM_API,
  MARK_SPEC = MARK_SPEC,
  SIGN_TYPE = SIGN_TYPE,
}
