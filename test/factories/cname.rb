FactoryGirl.define do
  factory :cname, class: CNAME do
    domain
    name { generate(:subdomain) }
    content { generate(:domain) }
  end
end
