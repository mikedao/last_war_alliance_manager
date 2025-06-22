require 'rails_helper'

RSpec.feature 'Alliance Bulk Player Creation', type: :feature do
  let(:alliance) { create(:alliance, tag: 'TEST') }
  let(:alliance_admin) { create(:user, role: :alliance_admin) }
  let!(:alliance_with_admin) { create(:alliance, admin: alliance_admin, tag: 'TEST') }

  before do
    visit login_path
    fill_in 'Username', with: alliance_admin.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end

  describe 'bulk add players' do
    it 'navigates to bulk add form when Bulk Add Players is clicked' do
      visit dashboard_path
      click_on 'Bulk Add Players'
      
      expect(page).to have_current_path(bulk_add_players_path)
      expect(page).to have_content('Bulk Add Players')
    end

    it 'creates multiple players successfully' do
      visit bulk_add_players_path
      
      fill_in 'Usernames (one per line)', with: "Player1\nPlayer2\nPlayer3"
      fill_in 'Ranks (one per line)', with: "R1\nR2\nR3"
      fill_in 'Levels (one per line)', with: "50\n60\n70"
      
      click_on 'Bulk Create Players'
      
      expect(page).to have_content('Bulk Import Results')
      expect(page).to have_content('Created: 3')
      expect(page).to have_content('Line 1: Player1')
      expect(page).to have_content('Line 2: Player2')
      expect(page).to have_content('Line 3: Player3')
    end

    it 'updates existing players' do
      create(:player, alliance: alliance_with_admin, username: 'Player1', rank: 'R1', level: 50)
      
      visit bulk_add_players_path
      
      fill_in 'Usernames (one per line)', with: 'Player1'
      fill_in 'Ranks (one per line)', with: 'R3'
      fill_in 'Levels (one per line)', with: '75'
      
      click_on 'Bulk Create Players'
      
      expect(page).to have_content('Updated: 1')
      expect(page).to have_content('Line 1: Player1')
      
      # Verify the player was updated
      visit players_path
      expect(page).to have_content('Player1')
      expect(page).to have_content('R3')
      expect(page).to have_content('75')
    end

    it 'handles validation errors gracefully' do
      visit bulk_add_players_path
      
      fill_in 'Usernames (one per line)', with: "Player1\nPlayer2"
      fill_in 'Ranks (one per line)', with: "R1\nINVALID"
      fill_in 'Levels (one per line)', with: "50\n60"
      
      click_on 'Bulk Create Players'
      
      expect(page).to have_content('Failed: 1')
      expect(page).to have_content('Rank must be R1, R2, R3, R4, or R5')
    end

    it 'processes only complete sets' do
      visit bulk_add_players_path
      
      fill_in 'Usernames (one per line)', with: "Player1\nPlayer2\nPlayer3"
      fill_in 'Ranks (one per line)', with: "R1\nR2"
      fill_in 'Levels (one per line)', with: "50\n60\n70"
      
      click_on 'Bulk Create Players'
      
      expect(page).to have_content('Created: 2')
      expect(page).to have_content('Line 1: Player1')
      expect(page).to have_content('Line 2: Player2')
      expect(page).not_to have_content('Line 3: Player3')
    end

    it 'handles empty input gracefully' do
      visit bulk_add_players_path
      
      fill_in 'Usernames (one per line)', with: ''
      fill_in 'Ranks (one per line)', with: ''
      fill_in 'Levels (one per line)', with: ''
      
      click_on 'Bulk Create Players'
      
      expect(page).to have_content('Created: 0')
      expect(page).to have_content('Updated: 0')
      expect(page).to have_content('Failed: 0')
    end

    it 'provides navigation back to players list' do
      visit bulk_add_players_path
      
      click_on 'Cancel'
      
      expect(page).to have_current_path(players_path)
    end

    it 'provides navigation from results page' do
      visit bulk_add_players_path
      
      fill_in 'Usernames (one per line)', with: 'Player1'
      fill_in 'Ranks (one per line)', with: 'R1'
      fill_in 'Levels (one per line)', with: '50'
      
      click_on 'Bulk Create Players'
      
      click_on 'View All Players'
      
      expect(page).to have_current_path(players_path)
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

      it 'redirects to dashboard with alert' do
        visit bulk_add_players_path
        
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

      it 'redirects to dashboard with alert' do
        visit bulk_add_players_path
        
        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You must be an alliance admin or manager to manage players.')
      end
    end
  end
end
