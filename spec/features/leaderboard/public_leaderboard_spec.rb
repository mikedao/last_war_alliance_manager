require 'rails_helper'

RSpec.feature 'Public Leaderboard', type: :feature do
  describe 'visiting the leaderboard page' do
    it 'successfully displays the leaderboard for a valid alliance tag' do
      # Setup
      alliance = create(:alliance, tag: 'TEST')
      
      # Action
      visit '/TEST'
      
      # Assertion
      expect(page).to have_content("Leaderboard for #{alliance.name}")
      expect(page).to have_content('Top Daily Performers')
    end

    it 'shows a not found page for an invalid 4-character tag' do
      # Action
      visit '/XXXX'
      
      # Assertion
      expect(page).to have_content("Alliance not found")
      expect(page.status_code).to eq(404)
    end

    it 'does not match the route for a tag that is not 4 characters' do
      # Action
      visit '/INVALID'
      
      # Assertion
      expect(page).to have_content("Routing Error")
      expect(page).not_to have_content("Alliance not found")
    end
  end

  describe 'Top Daily Performers section' do
    let!(:alliance) { create(:alliance, tag: 'TEST') }
    let!(:active_player) { create(:player, alliance: alliance, username: 'ActivePlayer') }
    let!(:inactive_player) { create(:player, :inactive, alliance: alliance, username: 'InactivePlayer') }

    it 'displays data for the latest locked day of the most recent duel' do
      # Setup: Old duel, should be ignored
      old_duel = create(:alliance_duel, alliance: alliance, start_date: 1.week.ago)
      create(:duel_day, :locked, alliance_duel: old_duel, day_number: 1, name: 'Old Day')

      # Setup: Most recent duel
      recent_duel = create(:alliance_duel, alliance: alliance, start_date: 1.day.ago)
      day1 = create(:duel_day, alliance_duel: recent_duel, day_number: 1, name: 'Day One')
      day2 = create(:duel_day, :locked, alliance_duel: recent_duel, day_number: 2, name: 'Day Two') # This is the target
      
      # Setup: Scores for the correct day
      create(:duel_day_score, player: active_player, duel_day: day2, score: 100)

      visit '/TEST'

      expect(page).to have_content("Showing results for: Duel Started #{recent_duel.start_date.strftime('%B %d, %Y')} - Day 2: Day Two")
      expect(page).not_to have_content('Old Day')
    end

    it 'shows a message if no days are locked in the most recent duel' do
      create(:alliance_duel, alliance: alliance, start_date: 1.day.ago) # No days are locked

      visit '/TEST'

      expect(page).to have_content('No data to display until a day is locked')
    end

    it 'shows a message if no duels exist' do
      visit '/TEST'

      expect(page).to have_content('No data to display until a day is locked')
    end
  end

  describe 'summary statistics' do
    let!(:alliance) { create(:alliance, tag: 'TEST') }
    let!(:duel) { create(:alliance_duel, alliance: alliance, start_date: 1.day.ago) }
    let!(:locked_day) { create(:duel_day, :locked, alliance_duel: duel, score_goal: 100) }

    before do
      # --- Player Setup ---
      # 5 Active players
      # 1. Made Goal (120 > 100)
      # 2. Made Goal (100 = 100)
      # 3. Missed Goal (90 < 100)
      # 4. Missed Goal (0 < 100)
      # 5. NA Score (ignored in all calcs except total active player count)
      create(:duel_day_score, player: create(:player, alliance: alliance), duel_day: locked_day, score: 120)
      create(:duel_day_score, player: create(:player, alliance: alliance), duel_day: locked_day, score: 100)
      create(:duel_day_score, player: create(:player, alliance: alliance), duel_day: locked_day, score: 90)
      create(:duel_day_score, player: create(:player, alliance: alliance), duel_day: locked_day, score: 0)
      create(:duel_day_score, player: create(:player, alliance: alliance), duel_day: locked_day, score: nil)

      # Inactive player - should be ignored completely
      create(:duel_day_score, player: create(:player, :inactive, alliance: alliance), duel_day: locked_day, score: 200)

      visit '/TEST'
    end

    it 'displays the correct "Made Goal" statistics' do
      # 2 of 5 active players made the goal (120, 100). NA is not counted in the denominator.
      # So, 2 out of 4 active players with scores. 50%.
      # But the requirement was "percentage of active players", so 2/5 = 40%.
      # Total active players = 5. Made Goal = 2. Percentage = (2/5) * 100 = 40.0%
      # Let's clarify the denominator. The image shows X / Y (Z%).
      # Let's assume Y is total active players.
      expect(page).to have_content("Made Goal")
      expect(page).to have_content("2 / 5 (40.0%)")
    end

    it 'displays the correct "Missed Goal" count' do
      # 2 active players missed the goal (90, 0).
      expect(page).to have_content("Missed Goal")
      expect(page).to have_content("2")
    end

    it 'displays the correct "Average Score"' do
      # Average of scores from active players, ignoring NA.
      # (120 + 100 + 90 + 0) / 4 = 77.5
      expect(page).to have_content("Average Score")
      expect(page).to have_content("77.5")
    end
  end

  describe 'Navigation' do
    let(:alliance) { create(:alliance, tag: 'TEST') }
    let(:user) { create(:user, alliance: alliance) }

    before do
      visit login_path
      fill_in 'Username', with: user.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
    end

    it 'shows leaderboard link in navigation when user belongs to an alliance' do
      expect(page).to have_link('Leaderboard', href: '/TEST')
    end

    it 'does not show leaderboard link when user does not belong to an alliance' do
      click_on 'Logout'
      user_without_alliance = create(:user, alliance: nil, username: 'noalliance', email: 'noalliance@example.com')
      visit login_path
      fill_in 'Username', with: user_without_alliance.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
      visit root_path
      expect(page).not_to have_link('Leaderboard')
    end
  end

  describe 'case insensitivity' do
    let!(:alliance) { create(:alliance, tag: 'TEST', name: 'Test Alliance') }
    let!(:duel) { create(:alliance_duel, alliance: alliance, start_date: 1.day.ago) }
    let!(:locked_day) { create(:duel_day, :locked, alliance_duel: duel, score_goal: 100) }

    it 'allows access to the leaderboard with lowercase tag' do
      visit '/test'
      expect(page).to have_content('Leaderboard for Test Alliance')
    end

    it 'allows access to the leaderboard with mixed case tag' do
      visit '/TeSt'
      expect(page).to have_content('Leaderboard for Test Alliance')
    end
  end
end 
 