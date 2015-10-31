FactoryGirl.define do
  factory :ns, class: NS do
    domain
    name ''
    content { generate(:domain) }
  end
end
