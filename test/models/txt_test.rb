require 'test_helper'

class TXTTest < ActiveSupport::TestCase

  test 'saves' do
    rec = build(:txt)
    rec.valid?

    assert_empty rec.errors
    assert rec.save
  end

  [
    '""',
    '"The quick brown fox"'
  ].each { |txt|
    test "valid content #{txt}" do
      rec = build(:txt, content: txt)
      rec.valid?
      assert_empty rec.errors[:content], "#{txt.inspect} should be valid!"
    end
  }

  [
    '',
    '"',
    'no quotes',
  ].each { |txt|
    test "invalid content #{txt}" do
      rec = build(:txt, content: txt)
      rec.valid?
      assert_not_empty rec.errors[:content], "#{txt.inspect} should be invalid!"
    end
  }

end
