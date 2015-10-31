FactoryGirl.define do
  sequence(:byte) { |n| (n % 256).to_s }
  sequence(:nibble) { |n| (n % 16).to_s(16) }

  factory :v4_ptr, class: 'PTR' do
    domain factory: :v4_arpa_domain
    name { generate(:byte) }
    content { generate(:domain) }
  end

  factory :v6_ptr, class: 'PTR' do
    domain factory: :v6_arpa_domain
    name {
      all_nibbles = '0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa'.split('.').size
      domain_nibbles = domain.name.split('.').size
      missing = []
      (all_nibbles - domain_nibbles).times { missing << generate(:nibble) }

      missing.join('.')
    }
    content { generate(:domain) }
  end
end
