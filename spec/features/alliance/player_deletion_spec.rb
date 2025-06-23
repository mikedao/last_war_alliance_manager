require 'rails_helper'

RSpec.feature 'Alliance Player Deletion', type: :feature do
  let(:alliance_admin) { create(:user, role: :alliance_admin) }
  let!(:alliance) { create(:alliance, admin: alliance_admin, tag: 'TEST') }

  before do
    visit login_path
    fill_in 'Username', with: alliance_admin.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end

  describe 'deleting a player' do
    it 'shows a delete button for each player' do
      create(:player, alliance: alliance, username: 'PlayerToDelete')

      visit players_path

      within("tr[data-player-username='PlayerToDelete']") do
        expect(page).to have_button('Delete')
      end
    end

    it 'deletes a player with Turbo and shows a turbo-powered flash message' do
      player = create(:player, alliance: alliance, username: 'PlayerToDelete')

      visit players_path

      expect(page).to have_selector('turbo-frame[id="flash"]')

      within("tr[data-player-username='PlayerToDelete']") do
        click_on 'Delete'
      end

      expect(page).to have_content('Player deleted successfully!')
      expect(page).not_to have_content('PlayerToDelete')
    end

    it 'deletes the correct player when multiple players exist' do
      create(:player, alliance: alliance, username: 'PlayerToDelete')
      create(:player, alliance: alliance, username: 'OtherPlayer')

      visit players_path

      expect(page).to have_content('PlayerToDelete')
      expect(page).to have_content('OtherPlayer')

      within("tr[data-player-username='OtherPlayer']") do
        click_on 'Delete'
      end

      expect(page).to have_content('Player deleted successfully!')
      expect(page).to have_content('PlayerToDelete')
      expect(page).not_to have_content('OtherPlayer')
    end

    it 'works with active and inactive players' do
      create(:player, alliance: alliance, username: 'ActivePlayer', active: true)
      create(:player, alliance: alliance, username: 'InactivePlayer', active: false)

      visit players_path

      expect(page).to have_content('ActivePlayer')
      expect(page).to have_content('InactivePlayer')

      within("tr[data-player-username='InactivePlayer']") do
        click_on 'Delete'
      end

      expect(page).to have_content('Player deleted successfully!')
      expect(page).to have_content('ActivePlayer')
      expect(page).not_to have_content('InactivePlayer')
    end

    it 'works when filtering players' do
      create(:player, alliance: alliance, username: 'ActivePlayer', active: true)
      create(:player, alliance: alliance, username: 'InactivePlayer', active: false)

      visit players_path

      click_on 'Inactive Only'

      within("tr[data-player-username='InactivePlayer']") do
        click_on 'Delete'
      end

      expect(page).to have_content('Player deleted successfully!')
      expect(page).not_to have_content('InactivePlayer')
    end

    it 'updates the player count after deletion' do
      create(:player, alliance: alliance, username: 'PlayerToDelete')

      visit players_path

      expect(page).to have_content('PlayerToDelete')

      within("tr[data-player-username='PlayerToDelete']") do
        click_on 'Delete'
      end

      expect(page).to have_content('Player deleted successfully!')
      expect(page).not_to have_content('PlayerToDelete')
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
