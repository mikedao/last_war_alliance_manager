FactoryBot.define do
  factory :alliance do
    sequence(:name) { |n| "Test Alliance #{n}" }
    sequence(:tag) { |n| "A#{format('%03d', n % 1000)}" }
    description { "A test alliance for testing purposes" }
    server { "123" }
    association :admin, factory: :user
  end
end 
