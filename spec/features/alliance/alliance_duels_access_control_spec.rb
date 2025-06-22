require 'rails_helper'

RSpec.feature 'Alliance Duels Access Control', type: :feature do
  let(:alliance_admin) { create(:user, role: :alliance_admin) }
  let!(:alliance) { create(:alliance, admin: alliance_admin, tag: 'TEST') }
  let!(:alliance_duel) { create(:alliance_duel, alliance: alliance, start_date: Date.current) }

  describe 'alliance admin access' do
    before do
      visit login_path
      fill_in 'Username', with: alliance_admin.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
    end

    it 'allows alliance admin to access alliance duels index' do
      visit alliance_duels_path
      
      expect(page).to have_current_path(alliance_duels_path)
      expect(page).to have_content('Alliance Duels')
      expect(page).to have_link('Create New Duel')
    end

    it 'allows alliance admin to view individual alliance duel' do
      visit alliance_duel_path(alliance_duel)
      
      expect(page).to have_current_path(alliance_duel_path(alliance_duel))
      expect(page).to have_content('Alliance Duel')
    end

    it 'allows alliance admin to create new alliance duel' do
      visit new_alliance_duel_path
      
      expect(page).to have_current_path(new_alliance_duel_path)
      expect(page).to have_content('New Alliance Duel')
    end
  end

  describe 'alliance manager access' do
    let(:alliance_manager) { create(:user, alliance: alliance, role: :alliance_manager) }

    before do
      visit login_path
      fill_in 'Username', with: alliance_manager.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
    end

    it 'allows alliance manager to access alliance duels index' do
      visit alliance_duels_path
      
      expect(page).to have_current_path(alliance_duels_path)
      expect(page).to have_content('Alliance Duels')
      expect(page).to have_link('Create New Duel')
    end

    it 'allows alliance manager to view individual alliance duel' do
      visit alliance_duel_path(alliance_duel)
      
      expect(page).to have_current_path(alliance_duel_path(alliance_duel))
      expect(page).to have_content('Alliance Duel')
    end

    it 'allows alliance manager to create new alliance duel' do
      visit new_alliance_duel_path
      
      expect(page).to have_current_path(new_alliance_duel_path)
      expect(page).to have_content('New Alliance Duel')
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

      it 'redirects to dashboard with alert when trying to access alliance duels index' do
        visit alliance_duels_path
        
        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You are not authorized to perform this action.')
      end

      it 'redirects to dashboard with alert when trying to access individual alliance duel' do
        visit alliance_duel_path(alliance_duel)
        
        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You are not authorized to perform this action.')
      end

      it 'redirects to dashboard with alert when trying to create new alliance duel' do
        visit new_alliance_duel_path
        
        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You are not authorized to perform this action.')
      end
    end

    context 'when user belongs to an alliance but is not an admin or manager' do
      let(:regular_user) { create(:user, role: :user) }
      let!(:user_alliance) { create(:alliance, admin: create(:user, role: :alliance_admin)) }

      before do
        regular_user.update!(alliance: user_alliance)
        visit login_path
        fill_in 'Username', with: regular_user.username
        fill_in 'Password', with: 'password123'
        click_on 'Log In'
      end

      it 'redirects to dashboard with alert when trying to access alliance duels index' do
        visit alliance_duels_path
        
        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You are not authorized to perform this action.')
      end

      it 'redirects to dashboard with alert when trying to access individual alliance duel' do
        visit alliance_duel_path(alliance_duel)
        
        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You are not authorized to perform this action.')
      end

      it 'redirects to dashboard with alert when trying to create new alliance duel' do
        visit new_alliance_duel_path
        
        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('You are not authorized to perform this action.')
      end
    end

    context 'when user tries to access alliance duels from different alliance' do
      let(:other_alliance) { create(:alliance, tag: 'OTHR') }
      let(:other_admin) { create(:user, role: :alliance_admin) }
      let!(:other_alliance_with_admin) { create(:alliance, admin: other_admin, tag: 'OTHR') }
      let!(:other_duel) { create(:alliance_duel, alliance: other_alliance_with_admin, start_date: Date.current + 1.day) }

      before do
        visit login_path
        fill_in 'Username', with: alliance_admin.username
        fill_in 'Password', with: 'password123'
        click_on 'Log In'
      end

      it 'allows access to alliance duels index (shows only their alliance duels)' do
        visit alliance_duels_path
        
        expect(page).to have_current_path(alliance_duels_path)
        expect(page).to have_content('Alliance Duels')
        # Should not show duels from other alliance
        expect(page).not_to have_content(other_duel.start_date.to_s)
      end

      it 'redirects to alliance duels index when trying to access duel from different alliance' do
        visit alliance_duel_path(other_duel)
        
        expect(page).to have_current_path(alliance_duels_path)
        expect(page).to have_content('Duel not found.')
      end
    end
  end

  describe 'navigation from dashboard' do
    before do
      visit login_path
      fill_in 'Username', with: alliance_admin.username
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
    end

    it 'navigates to alliance duels when Manage Alliance Duels is clicked' do
      visit dashboard_path
      
      click_on 'Manage Alliance Duels'
      
      expect(page).to have_current_path(alliance_duels_path)
      expect(page).to have_content('Alliance Duels')
    end
  end
end 
