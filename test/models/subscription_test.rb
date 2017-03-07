require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase

  test 'single subscription for a domain' do
    domain = create(:domain_with_subscriptions)
    assert_equal 1, domain.opt_outs.count

    subscription = domain.opt_outs.first
    assert_equal true, subscription.disabled

    user = subscription.user
    user.reload

    assert_equal domain, user.subscriptions.first.domain
  end

  test 'mute all domains for a user' do
    d1 = create(:domain_with_subscriptions)
    d2 = create(:domain_with_subscriptions)
    user = create(:user)

    # Add user to the groups
    d1.group.users << user
    d2.group.users << user

    # Opt out from notifications
    user.mute_all_domains
    # Ensure this is re-entrant
    user.mute_all_domains

    # Assert 2 opt-out domains
    assert_equal 2, user.subscriptions.count
  end
end
