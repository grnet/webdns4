require 'test_helper'

class NAPTRTest < ActiveSupport::TestCase
  test 'saves' do
    rec = build(:naptr)
    rec.valid?

    assert_empty rec.errors
    assert rec.save
  end
end
