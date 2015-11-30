FactoryGirl.define do
  factory :ns, class: NS do
    domain
    name ''
    content { generate(:domain) }
  end

  factory :cd_ns, class: NS do
    association :domain, factory: :v4_arpa_domain
    name '192/29'
    content 'ns1.example.com'
  end
end
