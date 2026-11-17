package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local eq = MiniTest.expect.equality
local has_mark, has_no_mark = H.expect.has_mark, H.expect.has_no_mark
local is_null = H.expect.is_null
local child = H.new_child_neovim('hlmarks.mark')

-- / Module
-- -------------------------------------------------------------------------------------------------
describe('Module.mark', function()

  before_each(function()
    child.setup()
  end)

  teardown(function()
    child.stop()
  end)

  -- / Category
  -- -----------------------------------------------------------------------------------------------
  describe('data handling', function()

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('locals()', function()

      it('return empty table if buffer has not any local marks', function()
        -- Arrange
        child.prepare_words('foo')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)

        -- Act
        local actual = child.lua_get(string.format('SUT.locals(%d)', stage.buf))

        -- Assert
        eq({}, actual)
      end)

      it('return all local mark data in each buffers', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('ma')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)
        child.prepare_words('bar', 'baz')
        child.type_keys('mbjmc')
        local expected = {
          b = {
            buffer = stage.buf,
            row = 1,
          },
          c = {
            buffer = stage.buf,
            row = 2,
          },
        }

        -- Act
        local actual = child.lua_get(string.format('SUT.locals(%d)', stage.buf))

        -- Assert
        eq(expected, actual)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('globals()', function()

      it('return empty table if buffer has not any global marks', function()
        -- Arrange
        child.prepare_words('foo')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)

        -- Act
        local actual = child.lua_get(string.format('SUT.globals(%d)', stage.buf))

        -- Assert
        eq({}, actual)
      end)

      it('return all global mark data in each buffers', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mA')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)
        child.prepare_words('bar')
        child.type_keys('mB')
        local expected = {
          B = {
            buffer = stage.buf,
            row = 1,
          },
        }

        -- Act
        local actual = child.lua_get(string.format('SUT.globals(%d)', stage.buf))

        -- Assert
        eq(expected, actual)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('data_if_changed()', function()

      it('return nil if marks in buffer has not any change', function()
        -- Arrange
        local buf_id = child.prepare_words('foo')

        -- Act
        local actual = child.lua_get(string.format('SUT.data_if_changed(%d)', buf_id))

        -- Assert
        is_null(actual)
        -- eq({}, actual)
      end)

      it('return all mark data in buffer if even one mark have been changed', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mamA')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)
        child.prepare_words('bar', 'baz')
        child.type_keys('mbmcjmBmC')
        child.lua(string.format('SUT.cache(%d)', stage.buf))
        child.type_keys(':delm cC<CR><Esc>')
        local expected = {
          b = {
            buffer = stage.buf,
            row = 1,
          },
          B = {
            buffer = stage.buf,
            row = 2,
          },
        }

        -- Act
        local actual = child.lua_get(string.format('SUT.data_if_changed(%d)', stage.buf))

        -- Assert
        eq(expected, actual)
      end)

      it('return empty table if all marks in buffer have been removed', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mamA')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)
        child.prepare_words('bar', 'baz')
        child.type_keys('mbmcjmBmC')
        child.lua(string.format('SUT.cache(%d)', stage.buf))
        child.type_keys(':delm bcBC<CR><Esc>')

        -- Act
        local actual = child.lua_get(string.format('SUT.data_if_changed(%d)', stage.buf))

        -- Assert
        eq({}, actual)
      end)

    end)

  end)

  -- / Category
  -- -----------------------------------------------------------------------------------------------
  describe('cache handling', function()

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('cache()/extract_cache()', function()

      it('return empty string if buffer has not any cache', function()
        -- Arrange
        child.prepare_words('foo')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)

        -- Act
        local actual = child.lua_get(string.format('SUT.extract_cache(%d)', stage.buf))

        -- Assert
        eq('', actual)
      end)

      it('return empty table if buffer has not any marks', function()
        -- Arrange
        child.prepare_words('foo')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)

        -- Act
        local actual = child.lua_get(string.format('SUT.cache(%d)', stage.buf))

        -- Assert
        eq({}, actual)
      end)

      it('return cache/data of all marks in buffer', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mamA')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)
        child.prepare_words('bar', 'baz')
        child.type_keys('mbjmB')
        local expected_data = {
          b = {
            buffer = stage.buf,
            row = 1,
          },
          B = {
            buffer = stage.buf,
            row = 2,
          },
        }
        local expected_cache = 'b1B2'

        -- Act
        local actual_data = child.lua_get(string.format('SUT.cache(%d)', stage.buf))
        local actual_cache = child.lua_get(string.format('SUT.extract_cache(%d)', stage.buf))

        -- Assert
        eq(expected_data, actual_data)
        eq(expected_cache, actual_cache)
      end)

    end)

  end)

  -- / Category
  -- -----------------------------------------------------------------------------------------------
  describe('mark handling', function()

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('next_local()', function()

      it('return rightmost local mark if marks are used like [ab]', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mamb')

        -- Act
        local actual = child.lua_get([[SUT.next_local()]])

        -- Assert
        eq('c', actual)
      end)

      it('return first available local mark if marks are used like [abe]', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mambme')

        -- Act
        local actual = child.lua_get([[SUT.next_local()]])

        -- Assert
        eq('c', actual)
      end)

      it('return first available local mark if marks are used like [cdg]', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mcmdmg')

        -- Act
        local actual = child.lua_get([[SUT.next_local()]])

        -- Assert
        eq('a', actual)
      end)

      it('return nil if all local marks are used', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mambmcmdmemfmgmhmimjmkmlmmmnmompmqmrmsmtmumvmwmxmymz')

        -- Act
        local actual = child.lua_get([[SUT.next_local()]])

        -- Assert
        is_null(actual)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('next_global()', function()

      it('return first global mark if any marks are not used on all buffers', function()
        -- Arrange
        child.prepare_words('foo')

        -- Act
        local actual = child.lua_get([[SUT.next_global()]])

        -- Assert
        eq('A', actual)
      end)

      it('return rightmost global mark if marks are used like [AB]', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mAmB')

        -- Act
        local actual = child.lua_get([[SUT.next_global()]])

        -- Assert
        eq('C', actual)
      end)

      it('return rightmost global mark if marks are used like [AB] in other buffers', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mAmB')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)

        -- Act
        local actual = child.lua_get([[SUT.next_global()]])

        -- Assert
        eq('C', actual)
      end)

      it('return first available global mark if marks are used like [ABE]', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mAmBmE')

        -- Act
        local actual = child.lua_get([[SUT.next_global()]])

        -- Assert
        eq('C', actual)
      end)

      it('return first available global mark if marks are used like [CDG]', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mCmDmG')

        -- Act
        local actual = child.lua_get([[SUT.next_global()]])

        -- Assert
        eq('A', actual)
      end)

      it('return nil if all global marks are used', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mAmBmCmDmEmFmGmHmImJmKmLmMmNmOmPmQmRmSmTmUmVmWmXmYmZ')

        -- Act
        local actual = child.lua_get([[SUT.next_global()]])

        -- Assert
        is_null(actual)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('remove_on_line()', function()

      it('can remove all marks on current row only', function()
        -- Arrange
        local buf_id = child.prepare_words('foo')
        child.type_keys('mambmA')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)
        child.prepare_words('bar', 'baz')
        child.type_keys('mambmBjmcmCk')

        -- Act
        child.lua([[SUT.remove_on_line()]])
        local actual_current = child.grub_marks()
        child.move_to_buf(buf_id)
        local actual_other = child.grub_marks()

        -- Assert
        has_mark('a', actual_other)
        has_mark('b', actual_other)
        has_mark('A', actual_other)
        has_no_mark('a', actual_current)
        has_no_mark('b', actual_current)
        has_no_mark('B', actual_current)
        has_mark('c', actual_current)
        has_mark('C', actual_current)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('remove_all()', function()

      it('can remove all marks in current buffer only', function()
        -- Arrange
        local buf_id = child.prepare_words('foo')
        child.type_keys('mambmA')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)
        child.prepare_words('bar', 'baz')
        child.type_keys('mambmBjmcmCk')

        -- Act
        child.lua([[SUT.remove_all()]])
        local actual_current = child.grub_marks()
        child.move_to_buf(buf_id)
        local actual_other = child.grub_marks()

        -- Assert
        has_mark('a', actual_other)
        has_mark('b', actual_other)
        has_mark('A', actual_other)
        has_no_mark('a', actual_current)
        has_no_mark('b', actual_current)
        has_no_mark('B', actual_current)
        has_no_mark('c', actual_current)
        has_no_mark('C', actual_current)
      end)

    end)

    -- / Subject
    -- ---------------------------------------------------------------------------------------------
    describe('toggle()', function()

      it('can set local mark to current row if it does not exist', function()
        -- Arrange
        child.prepare_words('foo')

        -- Act
        child.lua([[SUT.toggle('a')]])
        local actual = child.grub_marks()

        -- Assert
        has_mark('a', actual)
      end)

      it('can set global mark to current row if it does not exist', function()
        -- Arrange
        child.prepare_words('foo')

        -- Act
        child.lua([[SUT.toggle('A')]])
        local actual = child.grub_marks()

        -- Assert
        has_mark('A', actual)
      end)

      it('can toggle local mark on current row only if it already exist', function()
        -- Arrange
        local buf_id = child.prepare_words('foo')
        child.type_keys('ma')
        local stage = child.append_stage()
        child.move_to_buf(stage.buf)
        child.prepare_words('bar')
        child.type_keys('ma')

        -- Act
        child.lua([[SUT.toggle('a')]])
        local actual_current = child.grub_marks()
        child.move_to_buf(buf_id)
        local actual_other = child.grub_marks()

        -- Assert
        has_mark('a', actual_other)
        has_no_mark('a', actual_current)
      end)

      it('can toggle global mark on current row if it already exist', function()
        -- Arrange
        child.prepare_words('foo')
        child.type_keys('mA')

        -- Act
        child.lua([[SUT.toggle('A')]])
        local actual = child.grub_marks()

        -- Assert
        has_no_mark('A', actual)
      end)

    end)

  end)

end)
