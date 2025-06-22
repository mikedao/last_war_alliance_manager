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

    it 'automatically creates six duel days when a new duel is created' do
      visit new_alliance_duel_path
      fill_in 'Start date', with: Date.today
      click_on 'Create Duel'

      expect(page).to have_current_path(alliance_duels_path)
      expect(page).to have_content("Duel created successfully.")
      
      # Verify the duel was created
      duel = AllianceDuel.last
      expect(duel.alliance).to eq(user.alliance)
      expect(duel.start_date).to eq(Date.today)
      
      # Verify six duel days were created with correct titles
      expect(duel.duel_days.count).to eq(6)
      
      expected_days = [
        { day_number: 1, name: 'Radar Training' },
        { day_number: 2, name: 'Base Expansion' },
        { day_number: 3, name: 'Age of Science' },
        { day_number: 4, name: 'Train Heroes' },
        { day_number: 5, name: 'Total Mobilization' },
        { day_number: 6, name: 'Enemy Buster' }
      ]
      
      expected_days.each do |expected_day|
        day = duel.duel_days.find_by(day_number: expected_day[:day_number])
        expect(day).to be_present
        expect(day).to be_a(DuelDay)
        expect(day.name).to eq(expected_day[:name])
        expect(day.score_goal).to be_present
      end
    end
  end

  describe 'deleting a duel' do
    it 'allows an alliance admin to delete a duel from the index page' do
      duel = create(:alliance_duel, alliance: user.alliance, start_date: Date.today)
      visit alliance_duels_path

      within('table') do
        expect(page).to have_selector('td', text: Date.today.strftime('%A, %B %d, %Y'))
        click_on 'Delete'
      end

      # Verify the row is removed via Hotwire without page reload
      expect(page).to have_content('Duel deleted successfully.')
      expect(page).not_to have_selector('td', text: Date.today.strftime('%A, %B %d, %Y'))
      expect(page).to have_current_path(alliance_duels_path)
    end
  end

  describe 'viewing a duel' do
    it 'shows a "View Details" link for each duel' do
      duel = create(:alliance_duel, alliance: user.alliance, start_date: Date.today)
      visit alliance_duels_path

      within("#duel_row_#{duel.id}") do
        expect(page).to have_link('View Details')
      end
    end

    it 'navigates to the duel details page with a date-based URL' do
      duel_date = Date.new(2025, 6, 22)
      duel = create(:alliance_duel, alliance: user.alliance, start_date: duel_date)
      visit alliance_duels_path

      click_link 'View Details'

      expect(page).to have_current_path("/dashboard/alliance_duels/#{duel_date.to_s}")
      expect(page).to have_content("Alliance Duel: #{duel_date.strftime('%Y-%m-%d')}")
    end

    it 'redirects to the index page if the duel is not found' do
      visit '/dashboard/alliance_duels/2099-01-01'
      expect(page).to have_current_path(alliance_duels_path)
      expect(page).to have_content('Duel not found.')
    end

    it 'displays a table with players and duel days' do
      duel_date = Date.new(2025, 6, 22)
      alliance = user.alliance
      create_list(:player, 5, alliance: alliance)
      duel = create(:alliance_duel, alliance: alliance, start_date: duel_date)

      visit alliance_duel_path(alliance_duel_start_date: duel.start_date)

      within('table') do
        # Check for headers (no 'Player' header now)
        duel.duel_days.each do |day|
          expect(page).to have_selector('th', text: day.name.upcase)
        end
        expect(page).to have_selector('th', text: 'TOTAL', count: 1)

        # Check for player rows
        alliance.players.each do |player|
          expect(page).to have_selector('td', text: player.username)
        end
      end
    end
  end

  describe 'editing a duel day goal', js: true do
    let(:duel_date) { Date.new(2025, 6, 22) }
    let!(:duel) { create(:alliance_duel, alliance: user.alliance, start_date: duel_date) }
    let!(:day_one) { duel.duel_days.find_by(day_number: 1) }

    before do
      # Set a unique initial goal to avoid ambiguous matches later
      day_one.update!(score_goal: 1111.0)
      visit alliance_duel_path(alliance_duel_start_date: duel.start_date)
    end

    it 'allows inline editing of the score goal' do
      # 1. Wait for the page to be ready by looking for our unique content.
      expect(page).to have_content('1111.0')

      # 2. Find the unique "edit" link for Day 1's goal and click it.
      find("a[href*='duel_days/#{day_one.id}/edit_goal']").click

      # 3. The form should now be on the page with increment/decrement buttons.
      within("turbo-frame#goal_duel_day_#{day_one.id}") do
        expect(page).to have_content('1111.0')
        # Click the increment button a few times to increase the value
        click_button '+'
        click_button '+'
        click_button '+'
        expect(page).to have_content('1111.3')
        click_button 'Save'
      end

      # 4. The page should update with the new value.
      expect(page).to have_content('1111.3')
      expect(page).not_to have_content('1111.0')

      # 5. Verify the change is persisted in the database.
      expect(day_one.reload.score_goal).to eq(1111.3)
    end
  end

  describe 'locking duel days', js: true do
    let(:duel_date) { Date.new(2025, 6, 22) }
    let!(:duel) { create(:alliance_duel, alliance: user.alliance, start_date: duel_date) }
    let!(:day_one) { duel.duel_days.find_by(day_number: 1) }

    before do
      visit alliance_duel_path(alliance_duel_start_date: duel.start_date)
    end

    it 'allows alliance admins to lock and unlock days' do
      within("turbo-frame#lock_button_duel_day_#{day_one.id}") do
        expect(page).to have_button('Lock')
        click_button 'Lock'
        expect(page).to have_button('Locked')
        click_button 'Locked'
        expect(page).to have_button('Lock')
      end
      expect(day_one.reload.locked?).to be false
    end

    it 'does not prevent editing goals when day is locked' do
      within("turbo-frame#lock_button_duel_day_#{day_one.id}") do
        click_button 'Lock'
        expect(page).to have_button('Locked')
      end
      within("turbo-frame#goal_duel_day_#{day_one.id}") do
        expect(page).to have_selector("a[href*='duel_days/#{day_one.id}/edit_goal']")
      end
    end

    # it 'allows alliance managers to lock and unlock days' do
    #   user.update!(role: :alliance_manager)
    #   visit logout_path
    #   visit login_path
    #   fill_in 'Username', with: user.username
    #   fill_in 'Password', with: 'password123'
    #   click_on 'Log In'
    #   visit alliance_duel_path(alliance_duel_start_date: duel.start_date)
    #   within("turbo-frame#lock_button_duel_day_#{day_one.id}") do
    #     expect(page).to have_button('Lock')
    #     click_button 'Lock'
    #     expect(page).to have_button('Locked')
    #   end
    # end

    it 'prevents regular users from locking days' do
      user.update!(role: :user)
      visit logout_path
      visit login_path
      fill_in 'Username', with: user.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
      visit alliance_duel_path(alliance_duel_start_date: duel.start_date)
      expect(page).not_to have_button('Lock')
    end
  end
end 
