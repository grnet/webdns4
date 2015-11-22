require 'test_helper'

class SPFTest < ActiveSupport::TestCase

  test 'saves' do
    rec = build(:spf)
    rec.valid?

    assert_empty rec.errors
    assert rec.save
  end

  [
    '""',
    '"The quick brown fox"'
  ].each { |spf|
    test "valid content #{spf}" do
      rec = build(:spf, content: spf)
      rec.valid?
      assert_empty rec.errors[:content], "#{spf.inspect} should be valid!"
    end
  }

  [
    '',
    '"',
    'no quotes',
  ].each { |spf|
    test "invalid content #{spf}" do
      rec = build(:spf, content: spf)
      rec.valid?
      assert_not_empty rec.errors[:content], "#{spf.inspect} should be invalid!"
    end
  }

end
