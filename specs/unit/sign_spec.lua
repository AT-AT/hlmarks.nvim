package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local eq = MiniTest.expect.equality
local has_sign, has_no_sign = H.expect.has_sign, H.expect.has_no_sign
local is_not_null = H.expect.is_not_null
local child = H.new_child_neovim('hlmarks.sign')

-- / Module
-- -------------------------------------------------------------------------------------------------
describe('Module.sign', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  local function set_sign(buf_id, row, mark)
    local exp = string.format(
      'vim.api.nvim_buf_set_extmark(%d, %d, %d, 0, { id = %d, sign_text = "%s" })',
      buf_id,
      child.ns_id(),
      row,
      string.byte(mark),
      mark
    )

    child.lua(exp)
  end

  -- / Category
  -- -----------------------------------------------------------------------------------------------
  describe('setup process', function()

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('setup()', function()

      it('can define highlights', function()
        -- Arrange
        local expected_keys = {
          'HlmarksBufferMarkSignHl',
          'HlmarksBufferMarkNumberHl',
          'HlmarksBufferMarkLineHl',
          'HlmarksFileMarkSignHl',
          'HlmarksFileMarkNumberHl',
          'HlmarksFileMarkLineHl',
        }

        -- Act
        child.lua([[SUT.setup()]])
        local actual = child.lua_get([[vim.api.nvim_get_hl(0, {})]])

        -- Assert
        for _, key in ipairs(expected_keys) do
          is_not_null(actual[key])
        end
      end)

    end)

  end)

  -- / Category
  -- -----------------------------------------------------------------------------------------------
  describe('sign handling', function()

    before_each(function()
      child.lua([[SUT.setup()]])
    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('sync()', function()

      describe('mark = {}, sign = {}', function()

        it('can invoke without error', function()
          -- Arrange
          local buf_id = child.prepare_words('foo')

          -- Act
          child.lua(string.format('SUT.sync(%d, {})', buf_id))
          local actual = child.grub_signs(buf_id)

          -- Assert
          eq(0, vim.tbl_count(actual))
        end)

      end)

      describe('mark = added, sign = {}', function()

        it('can add new sign', function()
          -- Arrange
          local buf_id = child.prepare_words('foo')

          -- Act
          child.lua(string.format('SUT.sync(%d, { a = { row = 1 } })', buf_id))
          local actual = child.grub_signs(buf_id)

          -- Assert
          has_sign({ sign = 'a', row = 0 }, actual)
          eq(1, vim.tbl_count(actual))
        end)

      end)

      describe('mark = moved, sign = previous', function()

        it('can update moved signs', function()
          -- Arrange
          local buf_id = child.prepare_words('foo', 'bar', 'baz', 'qux')
          set_sign(buf_id, 0, 'a')

          -- Act
          child.lua(string.format('SUT.sync(%d, { a = { row = 3 } })', buf_id))
          local actual = child.grub_signs(buf_id)

          -- Assert
          has_sign({ sign = 'a', row = 2 }, actual)
          eq(1, vim.tbl_count(actual))
        end)

      end)

      describe('mark = removed, sign = remain', function()

        it('can remove isolated signs', function()
          -- Arrange
          local buf_id = child.prepare_words('foo')
          set_sign(buf_id, 0, 'a')

          -- Act
          child.lua(string.format('SUT.sync(%d, {})', buf_id))
          local actual = child.grub_signs(buf_id)

          -- Assert
          has_no_sign('a', actual)
          eq(0, vim.tbl_count(actual))
        end)

        it('can remove non-exist signs on same row', function()
          -- Arrange
          local buf_id = child.prepare_words('foo')
          set_sign(buf_id, 0, 'a')
          set_sign(buf_id, 0, 'b')

          -- Act
          child.lua(string.format('SUT.sync(%d, { a = { row = 1 } })', buf_id))
          local actual = child.grub_signs(buf_id)

          -- Assert
          has_sign({ sign = 'a', row = 0 }, actual)
          has_no_sign('b', actual)
          eq(1, vim.tbl_count(actual))
        end)

      end)

      describe('mark = any, sign = with ones in other buffer', function()

        it('can sync signs in current buffer only', function()
          -- Arrange
          local buf_id = child.prepare_words('foo')
          set_sign(buf_id, 0, 'a')
          set_sign(buf_id, 0, 'b')
          local stage = child.append_stage()
          child.move_to_buf(stage.buf)
          child.prepare_words('bar', 'baz')
          set_sign(stage.buf, 0, 'a')
          set_sign(stage.buf, 0, 'b')

          -- Act
          child.lua(string.format('SUT.sync(%d, { b = { row = 2 } })', stage.buf))
          local actual_current = child.grub_signs(stage.buf)
          child.move_to_buf(buf_id)
          local actual_other = child.grub_signs(buf_id)

          -- Assert
          has_no_sign('a', actual_current)
          has_sign({ sign = 'b', row = 1 }, actual_current)
          eq(1, vim.tbl_count(actual_current))
          has_sign({ sign = 'a', row = 0 }, actual_other)
          has_sign({ sign = 'b', row = 0 }, actual_other)
          eq(2, vim.tbl_count(actual_other))
        end)

      end)

    end)

  end)

end)
