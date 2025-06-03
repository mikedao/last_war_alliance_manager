FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    display_name { "Test User" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :user }
  end
end
