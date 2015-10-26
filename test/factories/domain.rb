FactoryGirl.define do
  sequence(:domain) { |n| "example#{n}.com" }
  factory :domain do
    name { generate(:domain) }
    type 'NATIVE'
  end
end
