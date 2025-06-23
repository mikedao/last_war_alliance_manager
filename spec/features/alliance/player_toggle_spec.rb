require 'rails_helper'

RSpec.feature 'Alliance Player Toggle', type: :feature do
  let(:alliance_admin) { create(:user, role: :alliance_admin) }
  let!(:alliance) { create(:alliance, admin: alliance_admin, tag: 'TEST') }

  before do
    visit login_path
    fill_in 'Username', with: alliance_admin.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end

  describe 'toggling player status' do
    it 'shows the correct initial state for active players' do
      create(:player, alliance: alliance, username: 'ActivePlayer', active: true)

      visit players_path

      within("tr[data-player-username='ActivePlayer']") do
        expect(page).to have_content('Active')
        expect(page).to have_selector('input[type="checkbox"]')
      end
    end

    it 'shows the correct initial state for inactive players' do
      create(:player, alliance: alliance, username: 'InactivePlayer', active: false)

      visit players_path

      within("tr[data-player-username='InactivePlayer']") do
        expect(page).to have_content('Inactive')
        expect(page).to have_selector('input[type="checkbox"]')
      end
    end

    it 'toggles an active player to inactive' do
      create(:player, alliance: alliance, username: 'ActivePlayer', active: true)

      visit players_path

      within("tr[data-player-username='ActivePlayer']") do
        expect(page).to have_content('Active')
        find('td:nth-child(5) button[type="submit"]').click
      end

      # The status should be updated via Turbo Stream
      within("tr[data-player-username='ActivePlayer']") do
        expect(page).to have_content('Inactive')
      end
    end

    it 'toggles an inactive player to active' do
      create(:player, alliance: alliance, username: 'InactivePlayer', active: false)

      visit players_path

      within("tr[data-player-username='InactivePlayer']") do
        expect(page).to have_content('Inactive')
        find('td:nth-child(5) button[type="submit"]').click
      end

      # The status should be updated via Turbo Stream
      within("tr[data-player-username='InactivePlayer']") do
        expect(page).to have_content('Active')
      end
    end

    it 'updates the player count in filtered views' do
      create(:player, alliance: alliance, username: 'ActivePlayer', active: true)
      create(:player, alliance: alliance, username: 'InactivePlayer', active: false)

      visit players_path

      # Initially should see both players
      expect(page).to have_content('ActivePlayer')
      expect(page).to have_content('InactivePlayer')

      # Toggle active player to inactive
      within("tr[data-player-username='ActivePlayer']") do
        find('td:nth-child(5) button[type="submit"]').click
      end

      # Check active only filter
      click_on 'Active Only'
      expect(page).not_to have_content('ActivePlayer')
      expect(page).not_to have_content('InactivePlayer')

      # Check inactive only filter
      click_on 'Inactive Only'
      expect(page).to have_content('ActivePlayer')
      expect(page).to have_content('InactivePlayer')
    end

    it 'works with multiple players' do
      create(:player, alliance: alliance, username: 'ActivePlayer', active: true)
      create(:player, alliance: alliance, username: 'InactivePlayer', active: false)

      visit players_path

      # Toggle first player
      within("tr[data-player-username='ActivePlayer']") do
        find('td:nth-child(5) button[type="submit"]').click
      end

      # Toggle second player
      within("tr[data-player-username='InactivePlayer']") do
        find('td:nth-child(5) button[type="submit"]').click
      end

      # Both should now be toggled
      within("tr[data-player-username='ActivePlayer']") do
        expect(page).to have_content('Inactive')
      end

      within("tr[data-player-username='InactivePlayer']") do
        expect(page).to have_content('Active')
      end
    end

    it 'does not cause a page reload' do
      create(:player, alliance: alliance, username: 'ActivePlayer', active: true)

      visit players_path

      # Store the current URL
      current_url = page.current_url

      within("tr[data-player-username='ActivePlayer']") do
        find('td:nth-child(5) button[type="submit"]').click
      end

      # URL should remain the same (no page reload)
      expect(page.current_url).to eq(current_url)

      # Status should still be updated
      within("tr[data-player-username='ActivePlayer']") do
        expect(page).to have_content('Inactive')
      end
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

      it 'redirects to dashboard with alert when trying to access players management' do
        visit players_path

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

      it 'redirects to dashboard with alert when trying to access players management' do
        visit players_path

        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You must be an alliance admin or manager to manage players.')
      end
    end
  end
end
