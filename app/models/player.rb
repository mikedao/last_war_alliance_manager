class Player < ApplicationRecord
  belongs_to :alliance
  has_many :duel_day_scores, dependent: :destroy

  validates :username, presence: true, uniqueness: { scope: :alliance_id, case_sensitive: false }
  validates :rank, presence: true, format: { with: /\AR[1-5]\z/, message: "must be in the format R1, R2, R3, R4, or R5" }
  validates :level, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }

  scope :active, -> { where(active: true) }
end
