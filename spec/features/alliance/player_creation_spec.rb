require 'rails_helper'

RSpec.describe 'Alliance Player Creation', type: :feature do
  let(:admin_user) { create(:user, role: :alliance_admin) }
  let!(:alliance) { create(:alliance, admin: admin_user) }

  before do
    visit login_path
    fill_in 'Username', with: admin_user.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end

  describe 'creating a new player' do
    it 'navigates to the new player form when Create New Player is clicked' do
      visit "/alliances/#{alliance.id}/players"
      click_on 'Create New Player'
      expect(page).to have_current_path("/alliances/#{alliance.id}/players/new")
      expect(page).to have_content('Add New Player')
    end

    it 'creates a new player with valid data' do
      visit "/alliances/#{alliance.id}/players/new"

      fill_in 'Username', with: 'NewPlayer'
      select 'R3', from: 'Rank'
      fill_in 'Level', with: '75'
      fill_in 'Notes', with: 'A promising new recruit'
      check 'Active'

      click_on 'Create Player'

      expect(page).to have_current_path("/alliances/#{alliance.id}/players/new")
      expect(page).to have_content('Player created successfully!')
      visit "/alliances/#{alliance.id}/players"
      expect(page).to have_content('NewPlayer')
      expect(page).to have_content('R3')
      expect(page).to have_content('75')
      expect(page).to have_content('A promising new recruit')
    end

    it 'creates a new inactive player when active checkbox is unchecked' do
      visit "/alliances/#{alliance.id}/players/new"

      fill_in 'Username', with: 'InactivePlayer'
      select 'R2', from: 'Rank'
      fill_in 'Level', with: '60'
      fill_in 'Notes', with: 'On temporary leave'
      uncheck 'Active'

      click_on 'Create Player'

      expect(page).to have_current_path("/alliances/#{alliance.id}/players/new")
      expect(page).to have_content('Player created successfully!')
      visit "/alliances/#{alliance.id}/players"
      expect(page).to have_content('InactivePlayer')

      # Check that the player shows as inactive
      within('tbody') do
        expect(page).to have_selector("tr[data-player-username='InactivePlayer']")
        within("tr[data-player-username='InactivePlayer']") do
          expect(page).to have_content('Inactive')
        end
      end
    end

    it 'shows validation errors for invalid data' do
      visit "/alliances/#{alliance.id}/players/new"

      # Try to submit without required fields
      click_on 'Create Player'

      expect(page).to have_content('Username can\'t be blank')
      expect(page).to have_content('Rank can\'t be blank')
      expect(page).to have_content('Level can\'t be blank')
    end

    it 'validates rank format' do
      visit "/alliances/#{alliance.id}/players/new"

      fill_in 'Username', with: 'TestPlayer'
      fill_in 'Level', with: '50'
      fill_in 'Notes', with: 'Test notes'

      # Try invalid rank by selecting an invalid option
      select 'Select a rank', from: 'Rank'
      click_on 'Create Player'

      expect(page).to have_content('Rank can\'t be blank')
    end

    it 'validates level range' do
      visit "/alliances/#{alliance.id}/players/new"

      fill_in 'Username', with: 'TestPlayer'
      select 'R2', from: 'Rank'
      fill_in 'Notes', with: 'Test notes'

      # Try invalid level
      fill_in 'Level', with: '150'
      click_on 'Create Player'

      expect(page).to have_content('Level must be less than or equal to 100')
    end

    it 'validates level minimum' do
      visit "/alliances/#{alliance.id}/players/new"

      fill_in 'Username', with: 'TestPlayer'
      select 'R2', from: 'Rank'
      fill_in 'Notes', with: 'Test notes'

      # Try invalid level
      fill_in 'Level', with: '0'
      click_on 'Create Player'

      expect(page).to have_content('Level must be greater than or equal to 1')
    end

    it 'prevents duplicate usernames within the same alliance' do
      # Create a player first
      create(:player, username: 'ExistingPlayer', alliance: alliance)

      visit "/alliances/#{alliance.id}/players/new"

      fill_in 'Username', with: 'ExistingPlayer'
      select 'R3', from: 'Rank'
      fill_in 'Level', with: '70'
      fill_in 'Notes', with: 'Duplicate username'

      click_on 'Create Player'

      expect(page).to have_content('Username has already been taken')
    end

    it 'allows same username in different alliances' do
      other_alliance = create(:alliance, admin: create(:user))
      create(:player, username: 'SharedName', alliance: other_alliance)

      visit "/alliances/#{alliance.id}/players/new"

      fill_in 'Username', with: 'SharedName'
      select 'R3', from: 'Rank'
      fill_in 'Level', with: '70'
      fill_in 'Notes', with: 'Same name as other alliance'

      click_on 'Create Player'

      expect(page).to have_current_path("/alliances/#{alliance.id}/players/new")
      expect(page).to have_content('Player created successfully!')
      visit "/alliances/#{alliance.id}/players"
      expect(page).to have_content('SharedName')
    end
  end

  context 'when user does not belong to an alliance' do
    let(:user_without_alliance) { create(:user, role: :alliance_admin) }

    before do
      visit login_path
      fill_in 'Username', with: user_without_alliance.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
    end

    it 'redirects to dashboard with alert when trying to access new player form' do
      visit "/alliances/1/players/new"
      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content('You must belong to an alliance to manage players.')
    end
  end

  context 'when user belongs to an alliance but is not an alliance admin' do
    let(:regular_user) { create(:user, role: :user) }
    let!(:user_alliance) { create(:alliance, admin: create(:user)) }

    before do
      regular_user.update!(alliance: user_alliance)
      visit login_path
      fill_in 'Username', with: regular_user.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
    end

    it 'redirects to dashboard with alert when trying to access new player form' do
      visit "/alliances/#{user_alliance.id}/players/new"
      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content('You must be an alliance admin to manage players.')
    end
  end
end
