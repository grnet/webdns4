require 'test_helper'

class MXTest < ActiveSupport::TestCase

  test 'saves' do
    rec = build(:mx)
    rec.valid?
    assert_empty rec.errors
    assert rec.save
  end

  test 'supports prio' do
    rec = build(:mx)
    assert rec.supports_prio?, 'supports prio'
  end

  [
    0,
    10,
    65_535,
  ].each { |prio|
    test "valid prio #{prio}" do
      rec = build(:mx, prio: prio)
      rec.valid?
      assert_empty rec.errors[:prio], "#{prio} should be valid!"
    end
  }

  [
    -10,
    65_535 + 1,
    'str',
  ].each { |prio|
    test "invalid prio #{prio}" do
      rec = build(:mx, prio: prio)
      rec.valid?
      assert_not_empty rec.errors[:prio], "#{prio} should be invalid!"
    end
  }

end
