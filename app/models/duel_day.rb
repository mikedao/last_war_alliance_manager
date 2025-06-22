class DuelDay < ApplicationRecord
  belongs_to :alliance_duel
  has_many :duel_day_scores, dependent: :destroy

  validates :name, presence: true
  validates :day_number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 6 }
  validates :score_goal, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_initialize :set_default_locked, if: :new_record?
  after_initialize :set_default_score_goal, if: :new_record?

  private

  def set_default_locked
    self.locked = false if locked.nil?
  end

  def set_default_score_goal
    self.score_goal = 0 if score_goal.nil?
  end
end
