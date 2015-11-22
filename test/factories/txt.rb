FactoryGirl.define do
  factory :txt, class: 'TXT' do
    domain
    name ''
    content '"v=spf1 a:mail.example.com -all"'
  end
end
