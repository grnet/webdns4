FactoryGirl.define do
  factory :aaaa, class: 'AAAA' do
    domain
    name { generate(:subdomain) }
    content '::1'
  end
end
