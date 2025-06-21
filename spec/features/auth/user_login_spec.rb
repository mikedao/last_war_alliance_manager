require 'rails_helper'

RSpec.describe 'User Login', type: :feature do
  let!(:user) { create(:user, username: 'loginuser', display_name: 'Login User', email: 'login@example.com', password: 'password123', password_confirmation: 'password123') }

  it 'allows a user to log in with valid credentials' do
    visit root_path
    click_on 'Login'
    fill_in 'Username', with: 'loginuser'
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
    expect(page).to have_current_path('/dashboard')
    expect(page).to have_button('Logout')
  end

  it 'shows an error for invalid credentials' do
    visit root_path
    click_on 'Login'
    fill_in 'Username', with: 'loginuser'
    fill_in 'Password', with: 'wrongpassword'
    click_on 'Log In'
    expect(page).to have_content('Invalid username or password')
    expect(page).to have_selector(:link_or_button, 'Log In')
    expect(page).to have_current_path('/login')
  end

  it 'shows errors for missing fields' do
    visit root_path
    click_on 'Login'
    click_on 'Log In'
    expect(page).to have_content("Username can't be blank")
    expect(page).to have_content("Password can't be blank")
  end
end
