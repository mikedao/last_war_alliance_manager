require 'rails_helper'

RSpec.describe 'User Sign Up', type: :feature do
  let(:existing_user) { User.create!(username: 'existinguser', display_name: 'Existing User', email: 'existing@example.com', password: 'password', password_confirmation: 'password') }

  it 'allows a user to sign up, auto-logs in, and shows their profile with alliance options' do
    visit root_path
    click_on 'Sign Up'
    fill_in 'Username', with: 'newuser'
    fill_in 'Display name', with: 'New User'
    fill_in 'Email', with: 'newuser@example.com'
    fill_in 'Password', with: 'securepassword'
    fill_in 'Password confirmation', with: 'securepassword'
    click_on 'Create Account'

    expect(page).to have_current_path('/profile')
    expect(page).to have_content('Username: newuser')
    expect(page).to have_content('Display name: New User')
    expect(page).to have_content('Email: newuser@example.com')
    expect(page).to have_content('Role: user')
    expect(page).to have_selector(:link_or_button, 'Create Alliance')
    expect(page).to have_content('For alliance leaders only!')
    expect(page).to have_selector(:link_or_button, 'Join Existing Alliance')
    expect(page).to have_selector(:link_or_button, 'Logout')
  end

  it 'shows an error if password and confirmation do not match' do
    visit signup_path
    fill_in 'Username', with: 'newuser2'
    fill_in 'Display name', with: 'New User2'
    fill_in 'Email', with: 'newuser2@example.com'
    fill_in 'Password', with: 'securepassword'
    fill_in 'Password confirmation', with: 'differentpassword'
    click_on 'Create Account'
    expect(page).to have_content("Password confirmation doesn't match Password")
  end

  it 'shows errors for missing required fields' do
    visit signup_path
    click_on 'Create Account'
    expect(page).to have_content("Username can't be blank")
    expect(page).to have_content("Display name can't be blank")
    expect(page).to have_content("Email can't be blank")
    expect(page).to have_content("Password can't be blank")
  end

  it 'shows an error if username or email is already taken' do
    existing_user
    visit signup_path
    fill_in 'Username', with: 'existinguser'
    fill_in 'Display name', with: 'Another User'
    fill_in 'Email', with: 'existing@example.com'
    fill_in 'Password', with: 'securepassword'
    fill_in 'Password confirmation', with: 'securepassword'
    click_on 'Create Account'
    expect(page).to have_content('Username has already been taken')
    expect(page).to have_content('Email has already been taken')
  end

  it 'shows an error for invalid email format' do
    visit signup_path
    fill_in 'Username', with: 'bademailuser'
    fill_in 'Display name', with: 'Bad Email User'
    fill_in 'Email', with: 'notanemail'
    fill_in 'Password', with: 'securepassword'
    fill_in 'Password confirmation', with: 'securepassword'
    click_on 'Create Account'
    expect(page).to have_content('Email is invalid')
  end
end
