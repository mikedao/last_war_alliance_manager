FactoryBot.define do
  factory :duel_day_score do
    association :duel_day
    association :player
    score { 10.5 }
  end
end 
