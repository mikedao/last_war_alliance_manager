class DuelDayScore < ApplicationRecord
  belongs_to :duel_day
  belongs_to :player

  validates :score, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
end
