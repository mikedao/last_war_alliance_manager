require 'rails_helper'

RSpec.describe 'Alliance Player Toggle', type: :feature do
  let(:admin_user) { create(:user, role: :alliance_admin) }
  let!(:alliance) { create(:alliance, admin: admin_user) }
  let!(:active_player) { create(:player, username: 'ActivePlayer', alliance: alliance, active: true) }
  let!(:inactive_player) { create(:player, username: 'InactivePlayer', alliance: alliance, active: false) }

  before do
    visit login_path
    fill_in 'Username', with: admin_user.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end

  describe 'toggling player status' do
    it 'shows the correct initial state for active players' do
      visit "/alliances/#{alliance.id}/players"
      
      within("tr[data-player-username='ActivePlayer']") do
        expect(page).to have_content('Active')
        expect(page).to have_selector('input[type="checkbox"]')
      end
    end

    it 'shows the correct initial state for inactive players' do
      visit "/alliances/#{alliance.id}/players"
      
      within("tr[data-player-username='InactivePlayer']") do
        expect(page).to have_content('Inactive')
        expect(page).to have_selector('input[type="checkbox"]')
      end
    end

    it 'toggles an active player to inactive' do
      visit "/alliances/#{alliance.id}/players"
      
      within("tr[data-player-username='ActivePlayer']") do
        expect(page).to have_content('Active')
        find('td:nth-child(5) button[type="submit"]').click
      end
      
      # Should update instantly via Turbo
      within("tr[data-player-username='ActivePlayer']") do
        expect(page).to have_content('Inactive')
      end
      
      # Verify the change persisted
      active_player.reload
      expect(active_player.active?).to be false
    end

    it 'toggles an inactive player to active' do
      visit "/alliances/#{alliance.id}/players"
      
      within("tr[data-player-username='InactivePlayer']") do
        expect(page).to have_content('Inactive')
        find('td:nth-child(5) button[type="submit"]').click
      end
      
      # Should update instantly via Turbo
      within("tr[data-player-username='InactivePlayer']") do
        expect(page).to have_content('Active')
      end
      
      # Verify the change persisted
      inactive_player.reload
      expect(inactive_player.active?).to be true
    end

    it 'updates the player count in filtered views' do
      visit "/alliances/#{alliance.id}/players"
      
      # Initially should have 1 active and 1 inactive
      click_on 'Active Only'
      expect(page).to have_content('ActivePlayer')
      expect(page).not_to have_content('InactivePlayer')
      
      click_on 'All Players'
      
      # Toggle the active player to inactive
      within("tr[data-player-username='ActivePlayer']") do
        find('td:nth-child(5) button[type="submit"]').click
      end
      
      # Now should have 0 active and 2 inactive
      click_on 'Active Only'
      expect(page).not_to have_content('ActivePlayer')
      expect(page).not_to have_content('InactivePlayer')
      
      click_on 'Inactive Only'
      expect(page).to have_content('ActivePlayer')
      expect(page).to have_content('InactivePlayer')
    end

    it 'works with multiple players' do
      third_player = create(:player, username: 'ThirdPlayer', alliance: alliance, active: true)
      
      visit "/alliances/#{alliance.id}/players"
      
      # Toggle first player
      within("tr[data-player-username='ActivePlayer']") do
        find('td:nth-child(5) button[type="submit"]').click
      end
      
      # Toggle third player
      within("tr[data-player-username='ThirdPlayer']") do
        find('td:nth-child(5) button[type="submit"]').click
      end
      
      # Verify both changes
      within("tr[data-player-username='ActivePlayer']") do
        expect(page).to have_content('Inactive')
      end
      
      within("tr[data-player-username='ThirdPlayer']") do
        expect(page).to have_content('Inactive')
      end
      
      # Inactive player should still be inactive
      within("tr[data-player-username='InactivePlayer']") do
        expect(page).to have_content('Inactive')
      end
    end

    it 'does not cause a page reload' do
      visit "/alliances/#{alliance.id}/players"
      
      # Store the current URL
      current_url = page.current_url
      
      within("tr[data-player-username='ActivePlayer']") do
        find('td:nth-child(5) button[type="submit"]').click
      end
      
      # Should still be on the same page
      expect(page.current_url).to eq(current_url)
      
      # Should still be on the players index
      expect(page).to have_content('Players in Your Alliance')
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
end 
