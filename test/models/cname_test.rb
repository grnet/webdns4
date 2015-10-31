require 'test_helper'

class CnameTest < ActiveSupport::TestCase
  setup do
    @record = build(:cname)
  end

  test 'save' do
    @record.save

    assert_empty @record.errors
  end

end
