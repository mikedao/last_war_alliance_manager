class DuelDayScore < ApplicationRecord
  belongs_to :duel_day
  belongs_to :player

  validates :score, presence: true
end
