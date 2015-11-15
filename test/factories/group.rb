FactoryGirl.define do
  factory :group do
    sequence(:name) { |n| "group-#{n}" }

    factory :group_with_users do
      after(:create) do |group|
        create_list(:user, 2).each { |u| group.users << u }
      end
    end
  end
end
