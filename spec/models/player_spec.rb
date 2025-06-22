require 'rails_helper'

RSpec.describe Player, type: :model do
  let(:alliance) { create(:alliance) }
  let(:valid_player) { build(:player, alliance: alliance) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(valid_player).to be_valid
    end

    it 'requires a username' do
      player = build(:player, username: nil, alliance: alliance)
      expect(player).not_to be_valid
      expect(player.errors[:username]).to include("can't be blank")
    end

    it 'requires a rank' do
      player = build(:player, rank: nil, alliance: alliance)
      expect(player).not_to be_valid
      expect(player.errors[:rank]).to include("can't be blank")
    end

    it 'requires a level' do
      player = build(:player, level: nil, alliance: alliance)
      expect(player).not_to be_valid
      expect(player.errors[:level]).to include("can't be blank")
    end

    it 'requires an alliance' do
      player = build(:player, alliance: nil)
      expect(player).not_to be_valid
      expect(player.errors[:alliance]).to include("must exist")
    end

    describe 'rank validation' do
      it 'accepts valid ranks' do
        %w[R1 R2 R3 R4 R5].each do |rank|
          player = build(:player, rank: rank, alliance: alliance)
          expect(player).to be_valid
        end
      end

      it 'rejects invalid ranks' do
        %w[R0 R6 R10 A1 B2].each do |rank|
          player = build(:player, rank: rank, alliance: alliance)
          expect(player).not_to be_valid
          expect(player.errors[:rank]).to include('must be in the format R1, R2, R3, R4, or R5')
        end
      end
    end

    describe 'level validation' do
      it 'accepts levels between 1 and 100' do
        [ 1, 50, 100 ].each do |level|
          player = build(:player, level: level, alliance: alliance)
          expect(player).to be_valid
        end
      end

      it 'rejects levels below 1' do
        player = build(:player, level: 0, alliance: alliance)
        expect(player).not_to be_valid
        expect(player.errors[:level]).to include('must be greater than or equal to 1')
      end

      it 'rejects levels above 100' do
        player = build(:player, level: 101, alliance: alliance)
        expect(player).not_to be_valid
        expect(player.errors[:level]).to include('must be less than or equal to 100')
      end
    end
  end

  describe 'associations' do
    it 'belongs to an alliance' do
      expect(valid_player).to respond_to(:alliance)
    end
  end

  describe 'defaults' do
    it 'defaults active to true' do
      player = Player.create!(
        username: 'testplayer',
        rank: 'R1',
        level: 50,
        alliance: alliance
      )
      expect(player.active).to be true
    end
  end
end
