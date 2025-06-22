require 'rails_helper'

RSpec.feature 'Alliance Duel Management', type: :feature do
  let(:user) { create(:user, :alliance_admin) }

  before do
    visit root_path
    click_on 'Login'
    fill_in 'Username', with: user.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end

  describe 'navigating to the duel management page' do
    it 'allows an alliance admin to navigate to the duel management page from the dashboard' do
      visit dashboard_path
      click_on 'Manage Alliance Duels'

      expect(page).to have_current_path('/dashboard/alliance_duels')
      expect(page).to have_content('Alliance Duels')
    end
  end

  describe 'authorization' do
    it 'redirects non-logged-in users to the root path' do
      # Log out the admin user from the main before block
      click_on 'Logout'

      visit '/dashboard/alliance_duels'
      expect(page).to have_current_path(root_path)
      expect(page).to have_content('You must be logged in to view your profile.')
    end

    it 'redirects non-admin users to the dashboard' do
      # Log out the admin user and log in as a regular user
      click_on 'Logout'
      non_admin_user = create(:user)
      visit root_path
      click_on 'Login'
      fill_in 'Username', with: non_admin_user.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'

      visit '/dashboard/alliance_duels'
      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content('You are not authorized to perform this action.')
    end
  end

  describe 'creating a new duel' do
    it 'shows a "Create New Duel" button on the index page' do
      visit alliance_duels_path
      expect(page).to have_link('Create New Duel')
    end

    it 'navigates to the new duel form' do
      visit alliance_duels_path
      click_on 'Create New Duel'

      expect(page).to have_current_path(new_alliance_duel_path)
      expect(page).to have_content('New Alliance Duel')
      expect(page).to have_field('Start date', with: Date.today.strftime('%Y-%m-%d'))
    end

    it 'creates a new alliance duel' do
      visit new_alliance_duel_path
      fill_in 'Start date', with: Date.today
      click_on 'Create Duel'

      expect(page).to have_current_path(alliance_duels_path)
      expect(page).to have_content("Duel created successfully.")
      
      within('table') do
        expect(page).to have_selector('td', text: Date.today.strftime('%A, %B %d, %Y'))
      end
    end
  end
end 
