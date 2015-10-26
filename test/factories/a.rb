FactoryGirl.define do
  factory :a do
    domain
    name { generate(:subdomain) }
    content '1.2.3.4'
  end
end
