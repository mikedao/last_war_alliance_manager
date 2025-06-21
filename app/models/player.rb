class Player < ApplicationRecord
  belongs_to :alliance

  validates :username, presence: true, uniqueness: { scope: :alliance_id, message: "has already been taken" }
  validates :rank, presence: true, inclusion: { in: %w[R1 R2 R3 R4 R5], message: "must be one of: R1, R2, R3, R4, R5" }
  validates :level, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }
end
