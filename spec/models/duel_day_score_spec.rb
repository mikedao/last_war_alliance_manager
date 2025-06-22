require 'rails_helper'

RSpec.describe DuelDayScore, type: :model do
  describe 'validations' do
    it { should validate_numericality_of(:score).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe 'associations' do
    it { should belong_to(:duel_day) }
    it { should belong_to(:player) }
  end
end
