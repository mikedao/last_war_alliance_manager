require 'rails_helper'

RSpec.feature 'Player Editing', type: :feature do
  let(:alliance_admin) { create(:user, role: :alliance_admin) }
  let!(:alliance) { create(:alliance, admin: alliance_admin, tag: 'TEST') }
  let!(:player) { create(:player, alliance: alliance, username: 'TestPlayer', rank: 'R3', level: 75, notes: 'Original notes', active: true) }

  describe 'alliance admin access' do
    before do
      visit login_path
      fill_in 'Username', with: alliance_admin.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
    end

    it 'allows alliance admin to access edit page for players in their alliance' do
      visit edit_player_path(player)
      
      expect(page).to have_current_path(edit_player_path(player))
      expect(page).to have_content('Edit Player')
      expect(page).to have_content('Update player information for TestPlayer')
    end

    it 'shows the edit form with current player data' do
      visit edit_player_path(player)
      
      expect(page).to have_field('Username', with: 'TestPlayer')
      expect(page).to have_select('Rank', selected: 'R3')
      expect(page).to have_field('Level', with: '75')
      expect(page).to have_field('Notes', with: 'Original notes')
      expect(page).to have_checked_field('Active')
    end

    it 'allows alliance admin to update player information' do
      visit edit_player_path(player)
      
      fill_in 'Username', with: 'UpdatedPlayer'
      select 'R4', from: 'Rank'
      fill_in 'Level', with: '85'
      fill_in 'Notes', with: 'Updated notes'
      uncheck 'Active'
      
      click_on 'Update Player'
      
      expect(page).to have_current_path(players_path)
      expect(page).to have_content('Player updated successfully!')
      
      # Verify the changes were saved
      expect(page).to have_content('UpdatedPlayer')
      expect(page).to have_content('R4')
      expect(page).to have_content('85')
      expect(page).to have_content('Updated notes')
      expect(page).to have_content('Inactive')
    end

    it 'shows validation errors for invalid data' do
      visit edit_player_path(player)
      
      fill_in 'Username', with: ''
      fill_in 'Level', with: '150'
      
      click_on 'Update Player'
      
      expect(page).to have_content('Please fix the following errors:')
      expect(page).to have_content("Username can't be blank")
      expect(page).to have_content('Level must be less than or equal to 100')
    end

    it 'prevents duplicate usernames within the same alliance' do
      create(:player, alliance: alliance, username: 'ExistingPlayer')
      
      visit edit_player_path(player)
      
      fill_in 'Username', with: 'ExistingPlayer'
      
      click_on 'Update Player'
      
      expect(page).to have_content('Username has already been taken')
    end

    it 'allows same username in different alliances' do
      other_alliance = create(:alliance, tag: 'OTHR')
      create(:player, alliance: other_alliance, username: 'SharedName')
      
      visit edit_player_path(player)
      
      fill_in 'Username', with: 'SharedName'
      
      click_on 'Update Player'
      
      expect(page).to have_content('Player updated successfully!')
    end

    it 'provides navigation back to players list' do
      visit edit_player_path(player)
      
      click_on 'Cancel'
      
      expect(page).to have_current_path(players_path)
    end
  end

  describe 'alliance manager access' do
    let(:alliance_manager) { create(:user, alliance: alliance, role: :alliance_manager) }

    before do
      visit login_path
      fill_in 'Username', with: alliance_manager.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
    end

    it 'allows alliance manager to access edit page for players in their alliance' do
      visit edit_player_path(player)
      
      expect(page).to have_current_path(edit_player_path(player))
      expect(page).to have_content('Edit Player')
      expect(page).to have_content('Update player information for TestPlayer')
    end

    it 'allows alliance manager to update player information' do
      visit edit_player_path(player)
      
      fill_in 'Username', with: 'ManagerUpdatedPlayer'
      select 'R5', from: 'Rank'
      fill_in 'Level', with: '95'
      fill_in 'Notes', with: 'Updated by manager'
      
      click_on 'Update Player'
      
      expect(page).to have_current_path(players_path)
      expect(page).to have_content('Player updated successfully!')
      
      # Verify the changes were saved
      expect(page).to have_content('ManagerUpdatedPlayer')
      expect(page).to have_content('R5')
      expect(page).to have_content('95')
      expect(page).to have_content('Updated by manager')
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

      it 'redirects to dashboard with alert when trying to access edit page' do
        visit edit_player_path(player)
        
        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You must be an alliance admin or manager to manage players.')
      end
    end

    context 'when user belongs to an alliance but is not an admin or manager' do
      let(:regular_user) { create(:user, role: :user) }
      let!(:user_alliance) { create(:alliance, admin: create(:user, role: :alliance_admin)) }

      before do
        regular_user.update!(alliance: user_alliance)
        visit login_path
        fill_in 'Username', with: regular_user.username
        fill_in 'Password', with: 'password123'
        click_on 'Log In'
      end

      it 'redirects to dashboard with alert when trying to access edit page' do
        visit edit_player_path(player)
        
        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You must be an alliance admin or manager to manage players.')
      end
    end

    context 'when user tries to access player from different alliance' do
      let(:other_alliance) { create(:alliance, tag: 'OTHR') }
      let(:other_admin) { create(:user, role: :alliance_admin) }
      let!(:other_alliance_with_admin) { create(:alliance, admin: other_admin, tag: 'OTHR') }
      let!(:other_player) { create(:player, alliance: other_alliance_with_admin, username: 'OtherPlayer') }

      before do
        visit login_path
        fill_in 'Username', with: alliance_admin.username
        fill_in 'Password', with: 'password123'
        click_on 'Log In'
      end

      it 'redirects to dashboard with alert when trying to access player from different alliance' do
        visit edit_player_path(other_player)
        
        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('Player not found or you don\'t have permission to access it.')
      end
    end
  end

  describe 'navigation from player index' do
    before do
      visit login_path
      fill_in 'Username', with: alliance_admin.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
    end

    it 'navigates to edit page when Edit link is clicked' do
      visit players_path
      
      within("tr[data-player-username='TestPlayer']") do
        click_on 'Edit'
      end
      
      expect(page).to have_current_path(edit_player_path(player))
      expect(page).to have_content('Edit Player')
    end
  end
end 
