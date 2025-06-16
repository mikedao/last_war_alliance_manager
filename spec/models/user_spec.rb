require 'rails_helper'

RSpec.describe User, type: :model do
  subject { FactoryBot.create(:user) }

  describe 'validations' do
    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username).case_insensitive }
    it { should validate_presence_of(:display_name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should have_secure_password }
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(%i[global_admin alliance_admin alliance_manager user]) }
  end

  describe 'factory' do
    it 'is valid with default attributes' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'creates a user with unique username and email' do
      user1 = create(:user)
      user2 = create(:user)
      expect(user1.username).not_to eq(user2.username)
      expect(user1.email).not_to eq(user2.email)
    end
  end

  describe '#role_name' do
    it 'returns "Global Admin" for global_admin role' do
      user = build(:user, role: :global_admin)
      expect(user.role_name).to eq('Global Admin')
    end

    it 'returns "Alliance Admin" for alliance_admin role' do
      user = build(:user, role: :alliance_admin)
      expect(user.role_name).to eq('Alliance Admin')
    end

    it 'returns "Alliance Manager" for alliance_manager role' do
      user = build(:user, role: :alliance_manager)
      expect(user.role_name).to eq('Alliance Manager')
    end

    it 'returns nil for user role' do
      user = build(:user, role: :user)
      expect(user.role_name).to be_nil
    end
  end
end
