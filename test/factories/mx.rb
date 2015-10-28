FactoryGirl.define do
  factory :mx, class: 'MX' do
    domain
    name ''
    prio 10
    content 'ns.example.com'
  end
end
