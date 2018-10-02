require 'test_helper'

class RecordTest < ActiveSupport::TestCase
  ['text', -1, 0, 2_147_483_647 + 1].each { |ttl|
    test "ttl invalid #{ttl}" do
      rec = build(:a, ttl: ttl)
      rec.valid?
      assert_not_empty rec.errors[:ttl], "ttl #{ttl} should be invalid!"
    end
  }

  ['', 1, 2_147_483_647].each { |ttl|
    test "ttl valid #{ttl}" do
      rec = build(:a, ttl: ttl)
      rec.valid?
      assert_empty rec.errors[:ttl], "ttl #{ttl} should be valid!"
    end
  }

end
