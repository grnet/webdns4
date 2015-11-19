require 'test_helper'

class CnameTest < ActiveSupport::TestCase
  setup do
    @record = build(:cname)
  end

  test 'save' do
    @record.save

    assert_empty @record.errors
  end

  test 'chop terminating dot' do
    @record.content = 'with-dot.example.com.'
    @record.save!
    @record.reload

    assert_equal 'with-dot.example.com', @record.content
  end

end
