require 'rails_helper'

RSpec.describe 'User Logout', type: :feature do
  let!(:user) { create(:user, username: 'logoutuser', display_name: 'Logout User', email: 'logout@example.com', password: 'password123', password_confirmation: 'password123') }

  it 'logs out a logged-in user and shows a flash message' do
    visit root_path
    click_on 'Login'
    fill_in 'Username', with: 'logoutuser'
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
    expect(page).to have_button('Logout')
    click_on 'Logout'
    expect(page).to have_content('You have been logged out.')
    expect(page).to have_current_path('/')
  end
end
