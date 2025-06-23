class User < ApplicationRecord
  has_secure_password

  has_one :owned_alliance, class_name: "Alliance", foreign_key: :admin_id, dependent: :nullify
  belongs_to :alliance, optional: true

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

  def alliance_admin?
    role == "alliance_admin"
  end

  def alliance_manager?
    role == "alliance_manager"
  end

  # Returns the alliance this user belongs to (either as admin or manager)
  def alliance
    if alliance_admin?
      owned_alliance
    else
      super
    end
  end
end
