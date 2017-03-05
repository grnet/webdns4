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
end
