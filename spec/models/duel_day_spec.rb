require 'rails_helper'

RSpec.describe DuelDay, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:day_number) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:score_goal) }
  end

  describe 'associations' do
    it { should belong_to(:alliance_duel) }
  end
end 
