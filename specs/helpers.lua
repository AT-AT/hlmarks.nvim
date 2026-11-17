-- Should clearing the module cache before loading this module.
--   package.loaded['tests/helpers'] = nil
--   local H = require('tests/helpers')
-- The reasons are as follows:
-- - In Lua and Neovim, required modules are cached until the process terminates.
-- - Because the "execution" of each test is performed in a child process, the tested module is
--   loaded for each test case, and the latest state is reflected.
-- - On the other hand, since this module is loaded in the process executing the test, the cache is
--   used and any changes to the implementation will not be reflected unless the current Neovim is
--   terminated.

local Helpers = {}

-- / Child Process Handling
-- -------------------------------------------------------------------------------------------------

---@class MiniTest.child
---@field setup function
---@field change_config function
---@field config_of function
---@field append_stage function
---@field move_to_buf function
---@field move_to_win function
---@field prepare_words function
---@field grub_marks function
---@field grub_signs function
---@field ns_id function

function Helpers.new_child_neovim(path)
  local child = MiniTest.new_child_neovim()

  function child.setup()
    child.restart({'-u', 'scripts/minimal_init.lua'})
    child.bo.readonly = false
    child.lua([[CONFIG_REF = require('hlmarks.config')]])
    child.lua([[OPTION_REF = CONFIG_REF.options]])
    child.lua("SUT = require('" .. tostring(path) .. "')")
  end

  -- / Configuration Helper
  -- -----------------------------------------------------------------------------------------------

  function child.change_config(expression)
    child.lua('OPTION_REF.' .. expression)
  end

  function child.config_of(name)
    return child.lua_get('CONFIG_REF.' .. name)
  end

  -- / Staging Helper
  -- -----------------------------------------------------------------------------------------------

  -- Note:
  --  - Since win=-1, it is splited and added at the top level (initial-created-window).
  --  - The added window does not become the current window.
  function child.append_stage()
    -- Creates a new buffer.
    -- Even if any buffer is created here, the current buffer will not change.
    local buf = child.api.nvim_create_buf(true, false)

    -- Creates a new window.
    -- Since the second parameter is set to false, the current buffer is not changed.
    local win = child.api.nvim_open_win(buf, false, { split = 'right', vertical = true, win = -1 })

    return { buf = buf, win = win }
  end

  function child.move_to_buf(buf_id)
    child.api.nvim_set_current_buf(buf_id)
  end

  function child.move_to_win(win_id)
    child.api.nvim_set_current_win(win_id)
  end

  -- Note:
  --  - Each element of the list = each word will be on a new line.
  --  - After inserting words, the cursor is set to (1, 0) = (1st row, 1st column).
  function child.prepare_words(...)
    local words = { ... }

    if vim.tbl_count(words) == 0 then
      words = { 'foo', 'Foo' }
    end

    child.api.nvim_buf_set_lines(0, 0, -1, true, words)
    child.api.nvim_win_set_cursor(0, { 1, 0 })

    return child.api.nvim_get_current_buf()
  end

  -- / Assertion Helper
  -- -----------------------------------------------------------------------------------------------
  function child.grub_marks()
    local marks = child.fn.getmarklist('%')
    local globals = child.fn.getmarklist()

    for _, v in ipairs(globals) do
      table.insert(marks, v)
    end

    return marks
  end

  function child.grub_signs(buf_id)
    return child.api.nvim_buf_get_extmarks(buf_id, child.ns_id(), 0, -1, { details = true })
  end

  function child.ns_id()
    local namespaces = child.api.nvim_get_namespaces()
    local plugin_name = child.config_of('plugin_name')

    return namespaces[plugin_name]
  end

  return child
end

-- / Custom Expectation
-- -------------------------------------------------------------------------------------------------

Helpers.expect = {}

Helpers.expect.has_mark = MiniTest.new_expectation(
  'mark existence determination',
  function(expected, actual)
    local matched = vim.tbl_filter(function (value)
      return value.mark == "'" .. expected
    end, actual)

    return vim.tbl_count(matched) == 1
  end,
  function(expected, actual)
    return string.format(
      'Expected mark (%s) does not exist in %s.', expected, vim.inspect(actual)
    )
  end
)

Helpers.expect.has_no_mark = MiniTest.new_expectation(
  'mark non-existence determination',
  function(non_expected, actual)
    local matched = vim.tbl_filter(function (value)
      return value.mark == "'" .. non_expected
    end, actual)

    return vim.tbl_count(matched) == 0
  end,
  function(non_expected, actual)
    return string.format(
      'The mark (%s) exists in %s.', non_expected, vim.inspect(actual)
    )
  end
)

Helpers.expect.has_sign = MiniTest.new_expectation(
  'sign existence determination',
  function(expected, actual)
    local sign, row = expected.sign, expected.row
    local matched = vim.tbl_filter(function (value)
      return value[1] == string.byte(sign) and value[2] == row
    end, actual)

    return vim.tbl_count(matched) == 1
  end,
  function(expected, actual)
    return string.format(
      'Expected sign (%s) does not exist in %s.', expected, vim.inspect(actual)
    )
  end
)

Helpers.expect.has_no_sign = MiniTest.new_expectation(
  'sign non-existence determination',
  function(non_expected, actual)
    local matched = vim.tbl_filter(function (value)
      return value[1] == string.byte(non_expected)
    end, actual)

    return vim.tbl_count(matched) == 0
  end,
  function(non_expected, actual)
    return string.format(
      'The sign (%s) exists in %s.', non_expected, vim.inspect(actual)
    )
  end
)

Helpers.expect.is_null = MiniTest.new_expectation(
  'null like value determination',
  function(value)
    return value == nil or value == vim.NIL
  end,
  function()
    return 'Value is neither nil nor vim.NIL.'
  end
)

Helpers.expect.is_not_null = MiniTest.new_expectation(
  'non-null like value determination',
  function(value)
    return value ~= nil and value ~= vim.NIL
  end,
  function()
    return 'Value is nil or vim.NIL.'
  end
)

-- / Inspection
-- -------------------------------------------------------------------------------------------------

function Helpers.p(thing)
  vim.print('--------------------------------------------------')
  vim.print(thing)
end

function Helpers.mc()
  vim.cmd('messages clear')
end

return Helpers
