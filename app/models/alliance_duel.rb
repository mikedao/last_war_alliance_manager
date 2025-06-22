class AllianceDuel < ApplicationRecord
  belongs_to :alliance
  has_many :duel_days, dependent: :destroy

  validates :start_date, presence: true

  after_create :create_default_duel_days

  private

  def create_default_duel_days
    duel_day_data = [
      { day_number: 1, name: 'Radar Training', score_goal: 1000 },
      { day_number: 2, name: 'Base Expansion', score_goal: 1000 },
      { day_number: 3, name: 'Age of Science', score_goal: 1000 },
      { day_number: 4, name: 'Train Heroes', score_goal: 1000 },
      { day_number: 5, name: 'Total Mobilization', score_goal: 1000 },
      { day_number: 6, name: 'Enemy Buster', score_goal: 1000 }
    ]

    duel_day_data.each do |day_data|
      duel_days.create!(day_data)
    end
  end
end
