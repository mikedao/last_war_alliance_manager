require 'rails_helper'

RSpec.describe 'Alliance Bulk Player Creation', type: :feature do
  let(:admin_user) { create(:user, role: :alliance_admin) }
  let!(:alliance) { create(:alliance, admin: admin_user) }

  before do
    visit login_path
    fill_in 'Username', with: admin_user.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end

  describe 'bulk add players' do
    it 'navigates to bulk add form when Bulk Add Players is clicked' do
      visit dashboard_path
      click_on 'Bulk Add Players'

      expect(page).to have_current_path(bulk_add_alliance_players_path(alliance))
      expect(page).to have_content('Bulk Add Players')
      expect(page).to have_field('Usernames (one per line)')
      expect(page).to have_field('Ranks (one per line)')
      expect(page).to have_field('Levels (one per line)')
    end

    it 'creates multiple players successfully' do
      visit bulk_add_alliance_players_path(alliance)

      fill_in 'Usernames (one per line)', with: "Player1\nPlayer2\nPlayer3"
      fill_in 'Ranks (one per line)', with: "R3\nR2\nR4"
      fill_in 'Levels (one per line)', with: "75\n60\n85"

      click_on 'Bulk Create Players'

      expect(page).to have_content('Bulk Import Results')
      expect(page).to have_content('Created: 3')
      expect(page).to have_content('Updated: 0')
      expect(page).to have_content('Failed: 0')
      expect(page).to have_content('Line 1: Player1 (Rank: R3, Level: 75)')
      expect(page).to have_content('Line 2: Player2 (Rank: R2, Level: 60)')
      expect(page).to have_content('Line 3: Player3 (Rank: R4, Level: 85)')
    end

    it 'updates existing players' do
      existing_player = create(:player, alliance: alliance, username: 'Player1', rank: 'R1', level: 50)

      visit bulk_add_alliance_players_path(alliance)

      fill_in 'Usernames (one per line)', with: 'Player1'
      fill_in 'Ranks (one per line)', with: 'R3'
      fill_in 'Levels (one per line)', with: '75'

      click_on 'Bulk Create Players'

      expect(page).to have_content('Created: 0')
      expect(page).to have_content('Updated: 1')
      expect(page).to have_content('Line 1: Player1 (Rank: R3, Level: 75)')

      existing_player.reload
      expect(existing_player.rank).to eq('R3')
      expect(existing_player.level).to eq(75)
    end

    it 'handles validation errors gracefully' do
      visit bulk_add_alliance_players_path(alliance)

      fill_in 'Usernames (one per line)', with: "Player1\nPlayer2\nPlayer3"
      fill_in 'Ranks (one per line)', with: "R3\nInvalidRank\nR4"
      fill_in 'Levels (one per line)', with: "75\n60\n150"

      click_on 'Bulk Create Players'

      expect(page).to have_content('Created: 1')
      expect(page).to have_content('Failed: 2')
      expect(page).to have_content('Line 1: Player1 (Rank: R3, Level: 75)')
      expect(page).to have_content('Rank must be R1, R2, R3, R4, or R5')
      expect(page).to have_content('Level must be between 1 and 100')
    end

    it 'processes only complete sets' do
      visit bulk_add_alliance_players_path(alliance)

      fill_in 'Usernames (one per line)', with: "Player1\nPlayer2\nPlayer3"
      fill_in 'Ranks (one per line)', with: "R3\nR2"
      fill_in 'Levels (one per line)', with: "75\n60\n85"

      click_on 'Bulk Create Players'

      expect(page).to have_content('Created: 2')
      expect(page).to have_content('Failed: 0')
      expect(page).to have_content('Line 1: Player1 (Rank: R3, Level: 75)')
      expect(page).to have_content('Line 2: Player2 (Rank: R2, Level: 60)')
      expect(page).not_to have_content('Player3')
    end

    it 'handles empty input gracefully' do
      visit bulk_add_alliance_players_path(alliance)

      click_on 'Bulk Create Players'

      expect(page).to have_content('Created: 0')
      expect(page).to have_content('Updated: 0')
      expect(page).to have_content('Failed: 0')
    end

    it 'provides navigation back to players list' do
      visit bulk_add_alliance_players_path(alliance)

      click_on 'Cancel'

      expect(page).to have_current_path(alliance_players_path(alliance))
    end

    it 'provides navigation from results page' do
      visit bulk_add_alliance_players_path(alliance)

      fill_in 'Usernames (one per line)', with: 'Player1'
      fill_in 'Ranks (one per line)', with: 'R3'
      fill_in 'Levels (one per line)', with: '75'

      click_on 'Bulk Create Players'

      click_on 'View All Players'

      expect(page).to have_current_path(alliance_players_path(alliance))
    end
  end

  describe 'access control' do
    context 'when user does not belong to an alliance' do
      let(:user_without_alliance) { create(:user, role: :alliance_admin) }

      before do
        visit login_path
        fill_in 'Username', with: user_without_alliance.username
        fill_in 'Password', with: 'password123'
        click_on 'Log In'
      end

      it 'redirects to dashboard with alert' do
        visit bulk_add_alliance_players_path(alliance)

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

      it 'redirects to dashboard with alert' do
        visit bulk_add_alliance_players_path(alliance)

        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You must be an alliance admin to manage players.')
      end
    end
  end
end
