class User < ApplicationRecord
  has_secure_password

  has_one :alliance, foreign_key: :admin_id, dependent: :nullify

  enum :role, { global_admin: 0, alliance_admin: 1, alliance_manager: 2, user: 3 }

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :display_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  def role_name
    case role
    when "global_admin"
      "Global Admin"
    when "alliance_admin"
      "Alliance Admin"
    when "alliance_manager"
      "Alliance Manager"
    end
  end
end
