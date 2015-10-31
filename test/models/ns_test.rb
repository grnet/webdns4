require 'test_helper'

class NSTest < ActiveSupport::TestCase
  setup do
    @record = build(:ns)
  end

  test 'save' do
    @record.save

    assert_empty @record.errors
  end

end
