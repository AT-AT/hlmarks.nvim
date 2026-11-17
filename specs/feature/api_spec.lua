package.loaded['specs/helpers'] = nil

local H = require('specs/helpers')
local has_mark, has_no_mark = H.expect.has_mark, H.expect.has_no_mark
local has_sign, has_no_sign = H.expect.has_sign, H.expect.has_no_sign
local child = H.new_child_neovim('hlmarks')

-- / API
-- -------------------------------------------------------------------------------------------------
describe('API', function()

  before_each(function()
    child.setup()
    child.lua([[require('hlmarks.sign').setup()]])
  end)

  teardown(function()
    child.stop()
  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('remove_all()', function()

    it('can remove all marks and signs using internal module', function()
      -- Arrange
      local buf_id = child.prepare_words('foo', 'bar')
      child.type_keys('majmA')
      child.lua(string.format('SUT.sync(%d)', buf_id))

      -- Act
      child.lua([[SUT.remove_all()]])
      local actual_marks = child.grub_marks()
      local actual_signs = child.grub_signs(buf_id)

      -- Assert
      has_no_mark('a', actual_marks)
      has_no_mark('A', actual_marks)
      has_no_sign('a', actual_signs)
      has_no_sign('A', actual_signs)
    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('remove_on_line()', function()

    it('can remove all marks and signs on current row using internal module', function()
      -- Arrange
      local buf_id = child.prepare_words('foo', 'bar')
      child.type_keys('mamAjmbmB')
      child.lua(string.format('SUT.sync(%d)', buf_id))

      -- Act
      child.lua([[SUT.remove_on_line()]])
      local actual_marks = child.grub_marks()
      local actual_signs = child.grub_signs(buf_id)

      -- Assert
      has_mark('a', actual_marks)
      has_mark('A', actual_marks)
      has_no_mark('b', actual_marks)
      has_no_mark('B', actual_marks)
      has_sign({ sign = 'a', row = 0 }, actual_signs)
      has_sign({ sign = 'A', row = 0 }, actual_signs)
      has_no_sign('b', actual_signs)
      has_no_sign('B', actual_signs)
    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('toggle()', function()

    it('can toggle mark using internal module', function()
      -- Arrange
      local buf_id = child.prepare_words('foo')
      child.type_keys('mamA')
      child.lua(string.format('SUT.sync(%d)', buf_id))

      -- Act
      child.lua([[SUT.set_mark('a')]])
      child.lua([[SUT.set_mark('A')]])
      child.lua([[SUT.set_mark('b')]])
      child.lua([[SUT.set_mark('B')]])
      local actual_marks = child.grub_marks()
      local actual_signs = child.grub_signs(buf_id)

      -- Assert
      has_no_mark('a', actual_marks)
      has_no_mark('A', actual_marks)
      has_mark('b', actual_marks)
      has_mark('B', actual_marks)
      has_no_sign('a', actual_signs)
      has_no_sign('A', actual_signs)
      has_sign({ sign = 'b', row = 0 }, actual_signs)
      has_sign({ sign = 'B', row = 0 }, actual_signs)
    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('set_next_buffer_mark()', function()

    it('can set unused buffer mark using internal module', function()
      -- Arrange
      local buf_id = child.prepare_words('foo')
      child.type_keys('ma')
      child.lua(string.format('SUT.sync(%d)', buf_id))

      -- Act
      child.lua([[SUT.set_next_buffer_mark()]])
      local actual_marks = child.grub_marks()
      local actual_signs = child.grub_signs(buf_id)

      -- Assert
      has_mark('a', actual_marks)
      has_mark('b', actual_marks)
      has_sign({ sign = 'a', row = 0 }, actual_signs)
      has_sign({ sign = 'b', row = 0 }, actual_signs)
    end)

  end)

  -- / Subject
  -- -----------------------------------------------------------------------------------------------
  describe('set_next_file_mark()', function()

    it('can set unused file mark using internal module', function()
      -- Arrange
      local buf_id = child.prepare_words('foo')
      child.type_keys('mA')
      child.lua(string.format('SUT.sync(%d)', buf_id))

      -- Act
      child.lua([[SUT.set_next_file_mark()]])
      local actual_marks = child.grub_marks()
      local actual_signs = child.grub_signs(buf_id)

      -- Assert
      has_mark('A', actual_marks)
      has_mark('B', actual_marks)
      has_sign({ sign = 'A', row = 0 }, actual_signs)
      has_sign({ sign = 'B', row = 0 }, actual_signs)
    end)

  end)

end)
