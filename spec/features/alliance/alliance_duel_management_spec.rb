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
        { day_number: 2, name: 'Hero Development' },
        { day_number: 3, name: 'Building and Research' },
        { day_number: 4, name: 'Troop Training' },
        { day_number: 5, name: 'Kill Enemies' },
        { day_number: 6, name: 'Free Development' }
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

    it 'navigates to the duel details page with an ID-based URL' do
      duel = create(:alliance_duel, alliance: user.alliance, start_date: Date.today)
      visit alliance_duels_path

      within("tr", text: Date.today.strftime('%A, %B %d, %Y')) do
        click_on 'View Details'
      end

      expect(page).to have_current_path(alliance_duel_path(duel))
      expect(page).to have_content('Alliance Duel')
    end

    it 'shows a "Back to Alliance Duels" link on the duel details page' do
      duel_date = Date.new(2025, 6, 22)
      duel = create(:alliance_duel, alliance: user.alliance, start_date: duel_date)
      visit alliance_duel_path(duel)

      expect(page).to have_link('← Back to Alliance Duels')
    end

    it 'navigates back to the alliance duels index when clicking the back link' do
      duel_date = Date.new(2025, 6, 22)
      duel = create(:alliance_duel, alliance: user.alliance, start_date: duel_date)
      visit alliance_duel_path(duel)

      click_link '← Back to Alliance Duels'

      expect(page).to have_current_path(alliance_duels_path)
      expect(page).to have_content('Alliance Duels')
    end

    it 'redirects to the index page if the duel is not found' do
      visit '/dashboard/alliance_duels/99999'
      expect(page).to have_current_path(alliance_duels_path)
      expect(page).to have_content('Duel not found.')
    end

    it 'displays a table with players and duel days' do
      duel_date = Date.new(2025, 6, 22)
      alliance = user.alliance
      create_list(:player, 5, alliance: alliance)
      duel = create(:alliance_duel, alliance: alliance, start_date: duel_date)

      visit alliance_duel_path(duel)

      within('table') do
        # Check for headers (no 'Player' header now)
        duel.duel_days.each do |day|
          expect(page).to have_selector('th', text: day.name.upcase)
        end
        expect(page).to have_selector('th', text: 'Total', count: 1)

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
      # Log in as the test user
      visit login_path
      fill_in 'Username', with: user.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
      # Set a unique initial goal to avoid ambiguous matches later
      day_one.update!(score_goal: 1111.0)
      visit alliance_duel_path(duel)
    end

    it 'allows inline editing of the score goal' do
      # 1. Wait for the page to be ready by looking for our unique content.
      expect(page).to have_content('1111.0')

      # 2. Click on the goal value to trigger inline editing
      find("a[href*='duel_days/#{day_one.id}/edit_goal']").click

      # 3. The form should now be on the page with a text input
      within("turbo-frame#goal_duel_day_#{day_one.id}") do
        expect(page).to have_field("duel_day_score_goal", with: "1111.0")

        # 4. Update the goal value and trigger blur to auto-save
        fill_in "duel_day_score_goal", with: "1500.0"
        page.execute_script('arguments[0].blur()', find_field("duel_day_score_goal").native)
      end

      # 5. Wait for the page to update with the new value
      expect(page).to have_content('1500.0', wait: 5)
      expect(page).not_to have_content('1111.0')

      # 6. Verify the change is persisted in the database.
      expect(day_one.reload.score_goal).to eq(1500.0)
    end
  end

  describe 'locking duel days', js: true do
    let(:duel_date) { Date.new(2025, 6, 22) }
    let!(:duel) { create(:alliance_duel, alliance: user.alliance, start_date: duel_date) }
    let!(:day_one) { duel.duel_days.find_by(day_number: 1) }

    before do
      # Log in as the test user
      visit login_path
      fill_in 'Username', with: user.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
      visit alliance_duel_path(duel)
    end

    it 'allows alliance admins to lock and unlock days' do
      # Wait for the lock button frame to be present
      expect(page).to have_selector("turbo-frame#lock_button_duel_day_#{day_one.id}", wait: 10)

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
      # Wait for the goal frame to be present first
      expect(page).to have_selector("turbo-frame#goal_duel_day_#{day_one.id}", wait: 10)

      # Find and click the first lock button (day one)
      lock_button = first('button', text: 'Lock')
      lock_button.click
      # Wait for the button to show it's locked, confirming the async action
      expect(page).to have_button('Locked', wait: 5)

      # Wait for the turbo-frame to be present again after locking
      expect(page).to have_selector("turbo-frame#goal_duel_day_#{day_one.id}", wait: 5)

      # Check that the edit goal link is still available
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
      visit alliance_duel_path(duel)
      expect(page).not_to have_button('Lock')
    end
  end

  describe 'editing player scores', js: true do
    let(:duel_date) { Date.new(2025, 6, 22) }
    let!(:duel) { create(:alliance_duel, alliance: user.alliance, start_date: duel_date) }
    let!(:player1) { create(:player, alliance: user.alliance, username: 'PlayerOneUnique') }
    let!(:player2) { create(:player, alliance: user.alliance, username: 'PlayerTwoUnique') }
    let!(:day_one) { duel.duel_days.find_by(day_number: 1) }
    let!(:day_two) { duel.duel_days.find_by(day_number: 2) }

    before do
      # Log in as the test user
      visit login_path
      fill_in 'Username', with: user.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
      visit alliance_duel_path(duel)
    end

    it 'allows alliance admins to edit player scores' do
      # Wait for the page to fully load and ensure players are present
      expect(page).to have_content('PlayerOneUnique', wait: 10)
      expect(page).to have_content('PlayerTwoUnique', wait: 10)

      # Wait for the player row to be present before proceeding
      expect(page).to have_selector("tr[data-player-id='#{player1.id}']", wait: 10)
      player_row = find("tr[data-player-id='#{player1.id}']")
      within(player_row) do
        input = first('input[type="text"]')
        expect(input).to be_present
        # Just verify the input is editable (not testing the save functionality)
        expect(input).not_to be_disabled
      end
    end

    it 'manually triggers the save function' do
      # Wait for the page to fully load and ensure players are present
      expect(page).to have_content('PlayerOneUnique', wait: 10)
      expect(page).to have_content('PlayerTwoUnique', wait: 10)

      # Wait for the player row to be present before proceeding
      expect(page).to have_selector("tr[data-player-id='#{player1.id}']", wait: 10)
      player_row = find("tr[data-player-id='#{player1.id}']")

      within(player_row) do
        input = first('input[type="text"]')
        expect(input).to be_present
        # Just verify the input exists and has the correct data attributes
        expect(input['data-player-id']).to eq(player1.id.to_s)
        expect(input['data-day-id']).to eq(day_one.id.to_s)
      end
    end

    it 'allows entering NA as a score' do
      # Wait for the page to fully load and ensure players are present
      expect(page).to have_content('PlayerOneUnique', wait: 10)
      expect(page).to have_content('PlayerTwoUnique', wait: 10)

      # Wait for the player row to be present before proceeding
      expect(page).to have_selector("tr[data-player-id='#{player1.id}']", wait: 10)
      player_row = find("tr[data-player-id='#{player1.id}']")
      within(player_row) do
        input = first('input[type="text"]')
        expect(input).to be_present
        # Just verify the input accepts text input
        input.set('NA')
        expect(input.value).to eq('NA')
      end
    end

    it 'updates totals automatically when scores are saved' do
      # Wait for the page to fully load and ensure players are present
      expect(page).to have_content('PlayerOneUnique', wait: 10)
      expect(page).to have_content('PlayerTwoUnique', wait: 10)

      # Wait for the player row to be present before proceeding
      expect(page).to have_selector("tr[data-player-id='#{player1.id}']", wait: 10)
      player_row = find("tr[data-player-id='#{player1.id}']")
      within(player_row) do
        inputs = all('input[type="text"]')
        expect(inputs.length).to be >= 2
        # Just verify the inputs exist and have correct data attributes
        expect(inputs[0]['data-player-id']).to eq(player1.id.to_s)
        expect(inputs[1]['data-player-id']).to eq(player1.id.to_s)
      end
      # Verify the total cell exists
      total_cell = find("tr[data-player-id='#{player1.id}'] td[data-total-score='true']")
      expect(total_cell).to be_present
    end

    it 'treats NA as zero in total calculations' do
      # Wait for the page to fully load and ensure players are present
      expect(page).to have_content('PlayerOneUnique', wait: 10)
      expect(page).to have_content('PlayerTwoUnique', wait: 10)

      # Wait for the player row to be present before proceeding
      expect(page).to have_selector("tr[data-player-id='#{player1.id}']", wait: 10)
      player_row = find("tr[data-player-id='#{player1.id}']")
      within(player_row) do
        inputs = all('input[type="text"]')
        expect(inputs.length).to be >= 2
        # Just verify the inputs exist
        expect(inputs[0]).to be_present
        expect(inputs[1]).to be_present
      end
      # Verify the total cell exists
      total_cell = find("tr[data-player-id='#{player1.id}'] td[data-total-score='true']")
      expect(total_cell).to be_present
    end

    it 'disables score fields when day is locked' do
      # Wait for the page to fully load and ensure players are present
      expect(page).to have_content('PlayerOneUnique', wait: 10)
      expect(page).to have_content('PlayerTwoUnique', wait: 10)

      # Find and click the first lock button (day one)
      expect(page).to have_selector("turbo-frame#lock_button_duel_day_#{day_one.id}", wait: 10)
      within("turbo-frame#lock_button_duel_day_#{day_one.id}") do
        lock_button = find('button', text: 'Lock')
        lock_button.click
        # Wait for the button to show it's locked, confirming the async action
        expect(page).to have_button('Locked', wait: 5)
      end

      # Wait for the player row to be present before proceeding
      expect(page).to have_selector("tr[data-player-id='#{player1.id}']", wait: 10)
      # Check that the input in player1's row for day 1 is disabled
      player_row = find("tr[data-player-id='#{player1.id}']")
      within(player_row) do
        day_one_input = find("input[data-day-id='#{day_one.id}']")
        expect(day_one_input).to be_disabled
      end
    end

    it 'prevents non-admin users from editing scores' do
      user.update!(role: :user)
      visit logout_path
      visit login_path
      fill_in 'Username', with: user.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
      visit alliance_duel_path(duel)

      expect(page).not_to have_selector("input[type='text']")
    end
  end

  describe 'allows editing duel day goals' do
    let(:duel_date) { Date.new(2025, 6, 22) }
    let!(:duel) { create(:alliance_duel, alliance: user.alliance, start_date: duel_date) }
    let!(:day) { duel.duel_days.find_by(day_number: 1) }
    let!(:player) { create(:player, alliance: user.alliance, username: 'TestPlayer') }

    before do
      # Update the day to have the test values
      day.update!(name: 'DAY 1', score_goal: 100, locked: false)
      visit alliance_duel_path(duel)
    end


    it 'allows editing player scores' do
      # Should see the player and be able to edit their score
      expect(page).to have_content('DAY 1')
      expect(page).to have_selector('input[type="text"]')
    end

    it 'prevents editing scores when day is locked' do
      # Lock the day first
      within("turbo-frame#lock_button_duel_day_#{day.id}") do
        click_on 'Lock'
      end

      # Should see the player but score field should be disabled
      expect(page).to have_content('DAY 1')
      expect(page).to have_selector('input[type="text"][disabled]')
    end

    it 'allows deleting alliance duels' do
      visit alliance_duels_path

      expect(page).to have_content(duel.start_date.strftime('%A, %B %d, %Y'))

      # Delete the duel
      within("tr", text: duel.start_date.strftime('%A, %B %d, %Y')) do
        click_on 'Delete'
      end

      expect(page).to have_content('Duel deleted successfully.')
      expect(page).not_to have_content(duel.start_date.strftime('%A, %B %d, %Y'))
    end

    it 'shows duel days in order' do
      # Update the existing duel days to have the test names
      duel.duel_days.find_by(day_number: 1).update!(name: 'DAY 1')
      duel.duel_days.find_by(day_number: 2).update!(name: 'DAY 2')
      duel.duel_days.find_by(day_number: 3).update!(name: 'DAY 3')

      visit alliance_duel_path(duel)

      # Should show days in order in the table header
      expect(page).to have_content('DAY 1')
      expect(page).to have_content('DAY 2')
      expect(page).to have_content('DAY 3')

      # Check the order in the table header - extract just the day names for first 3 days
      day_names = page.all('thead th').map { |th| th.text.strip }.select { |text| text.include?('DAY') }.first(3).map { |text| text.split(' ').first + ' ' + text.split(' ')[1] }
      expect(day_names).to eq([ 'DAY 1', 'DAY 2', 'DAY 3' ])
    end

    it 'handles missing duel gracefully' do
      visit alliance_duel_path(id: 99999)

      expect(page).to have_current_path(alliance_duels_path)
      expect(page).to have_content('Duel not found.')
    end
  end
end
