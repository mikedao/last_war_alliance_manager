require 'rails_helper'

RSpec.describe 'Profile Access', type: :feature do
  it 'redirects unauthenticated users to root path with alert message' do
    visit profile_path
    expect(page).to have_content('You must be logged in to view your profile.')
    expect(page).to have_current_path(root_path)
  end

  it 'allows authenticated users to access their profile' do
    user = create(:user, username: 'profileuser', display_name: 'Profile User', email: 'profile@example.com', password: 'password123', password_confirmation: 'password123')
    
    # Login first
    visit root_path
    click_on 'Login'
    fill_in 'Username', with: 'profileuser'
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
    
    # Now try to access profile
    visit profile_path
    expect(page).to have_current_path(profile_path)
    expect(page).to have_content('Profile User')
  end
end 
