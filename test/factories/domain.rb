FactoryGirl.define do
  sequence(:domain) { |n| "example#{n}.com" }
  factory :domain do
    group
    name { generate(:domain) }
    serial_strategy Strategies::Date
    type 'NATIVE'
  end

  factory :date_domain, class: Domain do
    group
    name { generate(:domain) }
    serial_strategy Strategies::Date
    type 'NATIVE'
  end

  factory :v4_arpa_domain, parent: :domain do
    name '2.0.192.in-addr.arpa'
  end

  factory :v6_arpa_domain, parent: :domain do
    name '8.b.d.0.1.0.0.2.ip6.arpa'
  end
end
