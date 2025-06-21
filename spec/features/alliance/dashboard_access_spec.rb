require 'rails_helper'

RSpec.describe 'Dashboard Access', type: :feature do
  let!(:alliance_admin) { create(:user, username: 'allianceadmin', display_name: 'Alliance Admin', email: 'alliance@example.com', password: 'password123', password_confirmation: 'password123', role: :alliance_admin) }
  let!(:global_admin) { create(:user, username: 'globaladmin', display_name: 'Global Admin', email: 'global@example.com', password: 'password123', password_confirmation: 'password123', role: :global_admin) }
  let!(:alliance_manager) { create(:user, username: 'alliancemanager', display_name: 'Alliance Manager', email: 'manager@example.com', password: 'password123', password_confirmation: 'password123', role: :alliance_manager) }
  let!(:regular_user) { create(:user, username: 'regularuser', display_name: 'Regular User', email: 'regular@example.com', password: 'password123', password_confirmation: 'password123', role: :user) }

  describe 'Navigation' do
    it 'shows dashboard link for alliance_admin' do
      login_as(alliance_admin)
      visit root_path
      expect(page).to have_link('Dashboard')
    end

    it 'shows dashboard link for global_admin' do
      login_as(global_admin)
      visit root_path
      expect(page).to have_link('Dashboard')
    end

    it 'shows dashboard link for alliance_manager' do
      login_as(alliance_manager)
      visit root_path
      expect(page).to have_link('Dashboard')
    end

    it 'does not show dashboard link for regular user' do
      login_as(regular_user)
      visit root_path
      expect(page).not_to have_link('Dashboard')
    end

    it 'does not show dashboard link when not logged in' do
      visit root_path
      expect(page).not_to have_link('Dashboard')
    end
  end

  describe 'Login Redirect' do
    it 'redirects alliance_admin to dashboard after login' do
      visit root_path
      click_on 'Login'
      fill_in 'Username', with: 'allianceadmin'
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
      expect(page).to have_current_path(dashboard_path)
    end

    it 'redirects global_admin to dashboard after login' do
      visit root_path
      click_on 'Login'
      fill_in 'Username', with: 'globaladmin'
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
      expect(page).to have_current_path(dashboard_path)
    end

    it 'redirects alliance_manager to dashboard after login' do
      visit root_path
      click_on 'Login'
      fill_in 'Username', with: 'alliancemanager'
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
      expect(page).to have_current_path(dashboard_path)
    end

    it 'redirects regular user to dashboard after login' do
      visit root_path
      click_on 'Login'
      fill_in 'Username', with: 'regularuser'
      fill_in 'Password', with: 'password123'
      click_on 'Log In'
      expect(page).to have_current_path(dashboard_path)
    end
  end

  describe 'Dashboard Access' do
    it 'allows alliance_admin to access dashboard' do
      login_as(alliance_admin)
      visit dashboard_path
      expect(page).to have_current_path(dashboard_path)
    end

    it 'allows global_admin to access dashboard' do
      login_as(global_admin)
      visit dashboard_path
      expect(page).to have_current_path(dashboard_path)
    end

    it 'allows alliance_manager to access dashboard' do
      login_as(alliance_manager)
      visit dashboard_path
      expect(page).to have_current_path(dashboard_path)
    end

    it 'allows regular user to access dashboard' do
      login_as(regular_user)
      visit dashboard_path
      expect(page).to have_current_path(dashboard_path)
    end
  end

  private

  def login_as(user)
    visit root_path
    click_on 'Login'
    fill_in 'Username', with: user.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end
end 
