class User < ApplicationRecord
  has_secure_password

  enum :role, { global_admin: 0, alliance_admin: 1, alliance_manager: 2, user: 3 }

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :display_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
end
