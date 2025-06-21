FactoryBot.define do
  factory :alliance do
    sequence(:name) { |n| "Test Alliance #{n}" }
    sequence(:tag) { |n| "TAG#{n.to_s.rjust(1, '0')}" }
    description { "A test alliance for testing purposes" }
    server { "123" }
    association :admin, factory: :user
  end
end 
