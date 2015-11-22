FactoryGirl.define do
  factory :spf, class: 'SPF' do
    domain
    name ''
    content '"v=spf1 a:mail.example.com -all"'
  end
end
