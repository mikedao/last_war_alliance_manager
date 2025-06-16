class Alliance < ApplicationRecord
  belongs_to :admin, class_name: "User"

  validates :name, presence: true
  validates :tag, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9]{4}\z/, message: "must be 4 alphanumeric characters" }
  validates :description, presence: true
  validates :server, presence: true, format: { with: /\A\d{1,5}\z/, message: "is invalid" }
end
