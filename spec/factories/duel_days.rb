FactoryBot.define do
  factory :duel_day do
    alliance_duel
    day_number { 1 }
    name { "Radar Training" }
    score_goal { 100_000 }
    locked { false }

    trait :locked do
      locked { true }
    end
  end
end
