FactoryBot.define do
  factory :player do
    association :alliance
    sequence(:username) { |n| "Player_#{n}" }
    rank { 'R4' }
    level { 25 }
    active { true }
    notes { 'A test player' }

    trait :inactive do
      active { false }
    end
  end
end
