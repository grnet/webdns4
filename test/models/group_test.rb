require 'test_helper'

class GroupTest < ActiveSupport::TestCase

  setup do
    @group = build(:group)
  end

  test 'save' do
    @group.save

    assert_empty @group.errors
  end
end
