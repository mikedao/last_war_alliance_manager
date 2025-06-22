FactoryBot.define do
  factory :alliance_duel do
    association :alliance
    start_date { Date.today }
  end
end
