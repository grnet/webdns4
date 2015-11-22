FactoryGirl.define do
  factory :naptr, class: 'NAPTR' do
    domain
    name ''
    content '100 10 "S" "SIP+D2U" "!^.*$!sip:customer-service@example.com!" _sip._udp.example.com'
  end
end
