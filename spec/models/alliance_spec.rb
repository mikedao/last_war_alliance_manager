require 'rails_helper'

RSpec.describe Alliance, type: :model do
  describe 'associations' do
    it { should belong_to(:admin).class_name('User') }
    it { should have_many(:players).dependent(:destroy) }
    it { should have_many(:alliance_duels).dependent(:destroy) }
  end

  describe 'validations' do
    subject { create(:alliance) } # Create a subject for uniqueness validation

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:tag) }
    it { should validate_uniqueness_of(:tag) }
    it { should allow_value('A1B2').for(:tag) }
    it { should_not allow_value('A1B').for(:tag).with_message('must be 4 alphanumeric characters') }
    it { should_not allow_value('A1B!').for(:tag).with_message('must be 4 alphanumeric characters') }

    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:server) }
    it { should allow_value('12345').for(:server) }
    it { should_not allow_value('abc').for(:server).with_message('is invalid') }
    it { should_not allow_value('123456').for(:server).with_message('is invalid') }
  end
end 
