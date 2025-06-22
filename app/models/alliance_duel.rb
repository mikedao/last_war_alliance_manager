class AllianceDuel < ApplicationRecord
  belongs_to :alliance

  validates :start_date, presence: true
end
