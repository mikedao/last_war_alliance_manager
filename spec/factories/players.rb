FactoryBot.define do
  factory :player do
    sequence(:username) { |n| "player#{n}" }
    rank { 'R1' }
    level { 50 }
    notes { 'A test player' }
    active { true }
    association :alliance
  end
end 
