class DuelDay < ApplicationRecord
  belongs_to :alliance_duel

  validates :day_number, presence: true
  validates :name, presence: true
  validates :score_goal, presence: true

  after_initialize :set_default_locked, if: :new_record?

  private

  def set_default_locked
    self.locked = false if locked.nil?
  end
end
