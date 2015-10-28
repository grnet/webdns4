require 'test_helper'

class AAAAATest < ActiveSupport::TestCase
  [
    '::',
    '2001:db8::',
    '2001:db8::1',
    '2001:0db8:0000:0000:0000:0000:0000:0001',
    '2001:DB8::1',
  ].each { |ip|
    test "content valid #{ip}" do
      rec = build(:aaaa, content: ip)
      rec.valid?
      assert_empty rec.errors[:content], "#{ip} should be valid!"
    end
  }

  [
    'noip',
    'no ip',
    '1.2.3.4.5',
    ':',
    '2001:db8::1::1',
    '[2001:db8::1]',
    '2001:0db8:0000:0000:0000:0000:0000:0000:0001',
  ].each { |ip|
    test "content invalid #{ip}" do
      rec = build(:aaaa, content: ip)
      rec.valid?
      assert_not_empty rec.errors[:content], "#{name} should be invalid!"
    end
  }

end
