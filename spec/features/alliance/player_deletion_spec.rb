require 'rails_helper'

RSpec.describe 'Alliance Player Deletion', type: :feature do
  let(:admin_user) { create(:user, role: :alliance_admin) }
  let!(:alliance) { create(:alliance, admin: admin_user) }
  let!(:player_to_delete) { create(:player, username: 'PlayerToDelete', alliance: alliance) }
  let!(:other_player) { create(:player, username: 'OtherPlayer', alliance: alliance) }

  before do
    visit login_path
    fill_in 'Username', with: admin_user.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end

  describe 'deleting a player' do
    it 'shows a delete button for each player' do
      visit "/alliances/#{alliance.id}/players"
      within("tr[data-player-username='PlayerToDelete']") do
        expect(page).to have_button('Delete')
      end
    end

    it 'deletes a player when delete button is clicked' do
      visit "/alliances/#{alliance.id}/players"
      
      within("tr[data-player-username='PlayerToDelete']") do
        click_on 'Delete'
      end
      
      expect(page).to have_current_path("/alliances/#{alliance.id}/players")
      expect(page).to have_content('Player deleted successfully!')
      expect(page).not_to have_content('PlayerToDelete')
      expect(page).to have_content('OtherPlayer') # Other player should still exist
    end

    it 'deletes the correct player when multiple players exist' do
      third_player = create(:player, username: 'ThirdPlayer', alliance: alliance)
      
      visit "/alliances/#{alliance.id}/players"
      
      # Delete the middle player
      within("tr[data-player-username='OtherPlayer']") do
        click_on 'Delete'
      end
      
      expect(page).to have_content('Player deleted successfully!')
      expect(page).to have_content('PlayerToDelete')
      expect(page).not_to have_content('OtherPlayer')
      expect(page).to have_content('ThirdPlayer')
    end

    it 'works with active and inactive players' do
      inactive_player = create(:player, username: 'InactivePlayer', alliance: alliance, active: false)
      
      visit "/alliances/#{alliance.id}/players"
      
      # Delete inactive player
      within("tr[data-player-username='InactivePlayer']") do
        click_on 'Delete'
      end
      
      expect(page).to have_content('Player deleted successfully!')
      expect(page).not_to have_content('InactivePlayer')
      expect(page).to have_content('PlayerToDelete')
    end

    it 'works when filtering players' do
      inactive_player = create(:player, username: 'InactivePlayer', alliance: alliance, active: false)
      
      visit "/alliances/#{alliance.id}/players"
      click_on 'Inactive Only'
      
      # Delete inactive player from filtered view
      within("tr[data-player-username='InactivePlayer']") do
        click_on 'Delete'
      end
      
      expect(page).to have_content('Player deleted successfully!')
      expect(page).not_to have_content('InactivePlayer')
      
      # Switch back to all players to confirm it's gone
      click_on 'All Players'
      expect(page).not_to have_content('InactivePlayer')
    end

    it 'updates the player count after deletion' do
      visit "/alliances/#{alliance.id}/players"
      
      # Should have 2 players initially
      expect(page).to have_content('PlayerToDelete')
      expect(page).to have_content('OtherPlayer')
      
      # Delete one player
      within("tr[data-player-username='PlayerToDelete']") do
        click_on 'Delete'
      end
      
      expect(page).to have_content('Player deleted successfully!')
      expect(page).not_to have_content('PlayerToDelete')
      expect(page).to have_content('OtherPlayer')
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

    it 'redirects to dashboard with alert when trying to access players management' do
      visit "/alliances/1/players"
      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content('You must belong to an alliance to manage players.')
    end
  end

  context 'when user belongs to an alliance but is not an alliance admin' do
    let(:regular_user) { create(:user, role: :user) }
    let!(:user_alliance) { create(:alliance, admin: create(:user)) }
    let!(:user_player) { create(:player, alliance: user_alliance) }

    before do
      regular_user.update!(alliance: user_alliance)
      visit login_path
      fill_in 'Username', with: regular_user.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
    end

    it 'redirects to dashboard with alert when trying to access players management' do
      visit "/alliances/#{user_alliance.id}/players"
      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content('You must be an alliance admin to manage players.')
    end
  end

  context 'when trying to delete a player from another alliance' do
    let!(:other_alliance) { create(:alliance, admin: create(:user)) }
    let!(:other_alliance_player) { create(:player, username: 'OtherAlliancePlayer', alliance: other_alliance) }

    it 'cannot see or access players from other alliances' do
      visit "/alliances/#{alliance.id}/players"
      
      # Should not see players from other alliance
      expect(page).not_to have_content('OtherAlliancePlayer')
      
      # The delete button for other alliance players should not exist
      expect(page).not_to have_selector("tr[data-player-username='OtherAlliancePlayer']")
    end
  end
end 
