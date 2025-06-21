require 'rails_helper'

RSpec.describe 'Alliance Players Management', type: :feature do
  let(:admin_user) { create(:user, role: :alliance_admin) }
  let!(:alliance) { create(:alliance, admin: admin_user) }
  let!(:active_player) { create(:player, username: 'activeplayer', active: true, alliance: alliance) }
  let!(:inactive_player) { create(:player, username: 'inactiveplayer', active: false, alliance: alliance) }
  let!(:other_alliance) { create(:alliance, admin: create(:user)) }
  let!(:other_player) { create(:player, username: 'otherplayer', alliance: other_alliance) }

  before do
    visit login_path
    fill_in 'Username', with: admin_user.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end

  it 'shows a Manage Players button in the dashboard for alliance_admins' do
    visit dashboard_path
    expect(page).to have_link('Manage Players')
  end

  it 'navigates to the players index when Manage Players is clicked' do
    visit dashboard_path
    click_on 'Manage Players'
    expect(page).to have_current_path("/alliances/#{alliance.id}/players")
    expect(page).to have_content('Players in Your Alliance')
  end

  it 'shows all players in the current user\'s alliance by default' do
    visit "/alliances/#{alliance.id}/players"
    expect(page).to have_content('activeplayer')
    expect(page).to have_content('inactiveplayer')
    expect(page).not_to have_content('otherplayer')
  end

  it 'shows players sorted alphabetically by username, case-insensitively' do
    create(:player, username: 'charlie', alliance: alliance)
    create(:player, username: 'Bravo', alliance: alliance)
    create(:player, username: 'alpha', alliance: alliance)

    visit "/alliances/#{alliance.id}/players"

    player_names = page.all('tbody tr td:first-child').map(&:text)
    expected_order = [ 'activeplayer', 'alpha', 'Bravo', 'charlie', 'inactiveplayer' ]
    expect(player_names).to eq(expected_order)
  end

  it 'can filter to show only active players' do
    visit "/alliances/#{alliance.id}/players"
    click_on 'Active Only'
    expect(page).to have_content('activeplayer')
    expect(page).not_to have_content('inactiveplayer')
  end

  it 'can filter to show only inactive players' do
    visit "/alliances/#{alliance.id}/players"
    click_on 'Inactive Only'
    within('tbody') do
      expect(page).to have_selector("tr[data-player-username='inactiveplayer']")
      expect(page).not_to have_selector("tr[data-player-username='activeplayer']")
    end
  end

  it 'shows a link to create a new player' do
    visit "/alliances/#{alliance.id}/players"
    expect(page).to have_link('Create New Player')
  end

  it 'shows edit, delete, and toggle active status actions for each player' do
    visit "/alliances/#{alliance.id}/players"
    within("tr[data-player-username='activeplayer']") do
      expect(page).to have_link('Edit')
      expect(page).to have_button('Delete')
      expect(page).to have_selector('input[type="checkbox"]')
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
