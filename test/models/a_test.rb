require 'test_helper'

class ATest < ActiveSupport::TestCase
  [
    '0.0.0.0',
    '1.2.3.4',
    '255.255.255.255',
  ].each { |ip|
    test "content valid #{ip}" do
      rec = build(:a, content: ip)
      rec.valid?
      assert_empty rec.errors[:content], "#{ip} should be valid!"
    end
  }

  [
    'noip',
    'no ip',
    '1.2',
    '1.2.3.4.5',
    '1.2.3.256',
    '1.2.3.4/24',
    '::1',
  ].each { |ip|
    test "content invalid #{ip}" do
      rec = build(:a, content: ip)
      rec.valid?
      assert_not_empty rec.errors[:content], "#{name} should be invalid!"
    end
  }

end
