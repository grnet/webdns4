FactoryGirl.define do
  factory :srv, class: 'SRV' do
    domain
    name '_service._proto.name.'
    prio 10
    content 'weight port target.'
  end
end
