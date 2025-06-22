require 'rails_helper'

RSpec.describe DuelDayScore, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:score) }
  end

  describe 'associations' do
    it { should belong_to(:duel_day) }
    it { should belong_to(:player) }
  end
end 
