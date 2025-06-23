require 'rails_helper'

RSpec.feature 'Alliance Player Creation', type: :feature do
  let(:alliance_admin) { create(:user, role: :alliance_admin) }
  let!(:alliance) { create(:alliance, admin: alliance_admin, tag: 'TEST') }

  before do
    visit login_path
    fill_in 'Username', with: alliance_admin.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end

  describe 'creating a new player' do
    it 'navigates to the new player form when Create New Player is clicked' do
      visit players_path
      click_on 'Create New Player'

      expect(page).to have_current_path(new_player_path)
      expect(page).to have_content('Add New Player')
    end

    it 'creates a new player with valid data' do
      visit new_player_path

      fill_in 'Username', with: 'NewPlayer'
      select 'R1', from: 'Rank'
      fill_in 'Level', with: '50'
      fill_in 'Notes', with: 'A test player'
      check 'Active'

      click_on 'Create Player'

      expect(page).to have_content('Player created successfully!')

      # Verify the player was created
      visit players_path
      expect(page).to have_content('NewPlayer')
      expect(page).to have_content('R1')
      expect(page).to have_content('50')
      expect(page).to have_content('A test player')
    end

    it 'creates a new inactive player when active checkbox is unchecked' do
      visit new_player_path

      fill_in 'Username', with: 'InactivePlayer'
      select 'R2', from: 'Rank'
      fill_in 'Level', with: '60'
      uncheck 'Active'

      click_on 'Create Player'

      expect(page).to have_content('Player created successfully!')

      # Verify the player was created as inactive
      visit players_path
      expect(page).to have_content('InactivePlayer')
      expect(page).to have_content('Inactive')
    end

    it 'shows validation errors for invalid data' do
      visit new_player_path

      # Submit without required fields
      click_on 'Create Player'

      expect(page).to have_content('Please fix the following errors:')
      expect(page).to have_content("Username can't be blank")
      expect(page).to have_content("Rank can't be blank")
      expect(page).to have_content("Level can't be blank")
    end

    it 'validates rank format' do
      visit new_player_path

      fill_in 'Username', with: 'TestPlayer'
      select 'R1', from: 'Rank'
      fill_in 'Level', with: '50'

      click_on 'Create Player'

      expect(page).to have_content('Player created successfully!')
    end

    it 'validates level range' do
      visit new_player_path

      fill_in 'Username', with: 'TestPlayer'
      select 'R1', from: 'Rank'
      fill_in 'Level', with: '150'

      click_on 'Create Player'

      expect(page).to have_content('Level must be less than or equal to 100')
    end

    it 'validates level minimum' do
      visit new_player_path

      fill_in 'Username', with: 'TestPlayer'
      select 'R1', from: 'Rank'
      fill_in 'Level', with: '0'

      click_on 'Create Player'

      expect(page).to have_content('Level must be greater than or equal to 1')
    end

    it 'prevents duplicate usernames within the same alliance' do
      create(:player, alliance: alliance, username: 'ExistingPlayer')

      visit new_player_path

      fill_in 'Username', with: 'ExistingPlayer'
      select 'R1', from: 'Rank'
      fill_in 'Level', with: '50'

      click_on 'Create Player'

      expect(page).to have_content('Username has already been taken')
    end

    it 'allows same username in different alliances' do
      other_alliance = create(:alliance, tag: 'OTHR')
      create(:player, alliance: other_alliance, username: 'SharedName')

      visit new_player_path

      fill_in 'Username', with: 'SharedName'
      select 'R1', from: 'Rank'
      fill_in 'Level', with: '50'

      click_on 'Create Player'

      expect(page).to have_content('Player created successfully!')
    end
  end

  describe 'access control' do
    context 'when user does not belong to an alliance' do
      let(:user_without_alliance) { create(:user, role: :user) }

      before do
        visit login_path
        fill_in 'Username', with: user_without_alliance.username
        fill_in 'Password', with: 'password123'
        click_on 'Log In'
      end

      it 'redirects to dashboard with alert when trying to access new player form' do
        visit new_player_path

        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You must be an alliance admin or manager to manage players.')
      end
    end

    context 'when user belongs to an alliance but is not an alliance admin' do
      let(:regular_user) { create(:user, role: :user) }
      let!(:user_alliance) { create(:alliance, admin: create(:user, role: :alliance_admin)) }

      before do
        regular_user.update!(alliance: user_alliance)
        visit login_path
        fill_in 'Username', with: regular_user.username
        fill_in 'Password', with: 'password123'
        click_on 'Log In'
      end

      it 'redirects to dashboard with alert when trying to access new player form' do
        visit new_player_path

        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You must be an alliance admin or manager to manage players.')
      end
    end
  end
end
