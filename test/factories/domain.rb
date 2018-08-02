FactoryGirl.define do
  sequence(:domain) { |n| "example#{n}.com" }
  sequence(:v4_gen_arpa_domain) { |n| "2.0.#{n}.in-addr.arpa" }
  sequence(:v6_gen_arpa_domain) { |n| "#{(n % 16).to_s(16)}.b.d.0.1.0.0.2.ip6.arpa" }

  factory :domain do
    group
    name { generate(:domain) }
    serial_strategy Strategies::Date
    type 'NATIVE'
  end

  factory :slave, parent: :domain do
    type 'SLAVE'
    master '1.2.3.4'
  end

  factory :date_domain, class: Domain do
    group
    name { generate(:domain) }
    serial_strategy Strategies::Date
    type 'NATIVE'
  end

  factory :v4_arpa_domain, parent: :domain do
    name { generate(:v4_gen_arpa_domain) }
  end

  factory :v6_arpa_domain, parent: :domain do
    name { generate(:v6_gen_arpa_domain) }
  end

  factory :domain_with_subscriptions, parent: :domain do
    association :group, factory: :group_with_users
    after(:create) do |domain|
      Subscription.create(domain: domain, user:domain.group.users.first)
    end
  end
end
