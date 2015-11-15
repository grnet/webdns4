require 'test_helper'

class MembershipTest < ActiveSupport::TestCase

  test 'single membership for a group' do
    group = create(:group_with_users)
    user = group.users.first

    assert_raise ActiveRecord::RecordInvalid do
      group.users << user
    end
  end
end
