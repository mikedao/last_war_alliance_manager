class AllianceDuel < ApplicationRecord
  belongs_to :alliance
  has_many :duel_days, dependent: :destroy

  validates :start_date, presence: true

  after_create :create_default_duel_days

  private

  def create_default_duel_days
    [
      { day_number: 1, name: "Radar Training", score_goal: 0 },
      { day_number: 2, name: "Hero Development", score_goal: 0 },
      { day_number: 3, name: "Building and Research", score_goal: 0 },
      { day_number: 4, name: "Troop Training", score_goal: 0 },
      { day_number: 5, name: "Kill Enemies", score_goal: 0 },
      { day_number: 6, name: "Free Development", score_goal: 0 }
    ].each do |day_data|
      duel_days.create!(day_data)
    end
  end
end
