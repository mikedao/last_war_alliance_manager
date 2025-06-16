require 'rails_helper'

RSpec.describe 'User Logout', type: :feature do
  let!(:user) { create(:user, username: 'logoutuser', display_name: 'Logout User', email: 'logout@example.com', password: 'password123', password_confirmation: 'password123') }

  it 'logs out a logged-in user and shows a flash message' do
    # Log in the user via sign up (since login is not implemented yet)
    visit signup_path
    fill_in 'Username', with: 'logoutuser2'
    fill_in 'Display name', with: 'Logout User2'
    fill_in 'Email', with: 'logout2@example.com'
    fill_in 'Password', with: 'password123'
    fill_in 'Password confirmation', with: 'password123'
    click_on 'Create Account'
    # Now user is logged in
    expect(page).to have_selector(:link_or_button, 'Logout')
    click_on 'Logout'
    expect(page).to have_content('You have been logged out.')
    expect(page).to have_selector(:link_or_button, 'Sign Up')
    expect(page).to have_selector(:link_or_button, 'Login')
  end
end
