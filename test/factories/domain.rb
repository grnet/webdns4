FactoryGirl.define do
  sequence(:domain) { |n| "example#{n}.com" }
  factory :domain do
    name { generate(:domain) }
    serial_strategy Strategies::Date
    type 'NATIVE'
  end

  factory :date_domain, class: Domain do
    name { generate(:domain) }
    serial_strategy Strategies::Date
    type 'NATIVE'
  end
end
