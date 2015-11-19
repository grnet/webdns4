require 'test_helper'

class NSTest < ActiveSupport::TestCase
  setup do
    @record = build(:ns)
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

  test 'drop privileges on zone NS records' do
    @record.drop_privileges = true
    @record.save

    assert_not_empty @record.errors[:name]
  end

  test 'doesnt drop privileges on non zone NS records' do
    @record.name = 'other'
    @record.drop_privileges = true

    @record.save

    assert_empty @record.errors[:name]
  end
end
