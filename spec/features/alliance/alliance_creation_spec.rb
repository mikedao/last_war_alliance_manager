require 'rails_helper'

RSpec.describe 'Alliance Creation', type: :feature do
  let(:user) { create(:user, username: 'leader1', display_name: 'Leader One', email: 'leader1@example.com', password: 'password123', password_confirmation: 'password123') }

  before do
    visit login_path
    fill_in 'Username', with: user.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end

  it 'allows a user to create an alliance, become alliance_admin, and see their alliance on the dashboard' do
    click_on 'Create Alliance'
    fill_in 'Alliance Name', with: 'The Survivors'
    fill_in 'Tag', with: 'A1B2'
    fill_in 'Description', with: 'The best alliance!'
    fill_in 'Server', with: '12345'
    click_on 'Create Alliance'

    expect(page).to have_current_path('/dashboard')
    expect(page).to have_content('Alliance: The Survivors')
    expect(page).to have_content('Tag: A1B2')
    expect(page).to have_content('Description: The best alliance!')
    expect(page).to have_content('Server: 12345')
    expect(page).to have_content('Role: Alliance Admin')
    expect(page).to have_content('Leader One')
    expect(page).not_to have_selector(:link_or_button, 'Create Alliance')
    expect(page).not_to have_selector(:link_or_button, 'Join Existing Alliance')
  end

  it 'shows errors for invalid or duplicate tag, invalid server, and missing fields' do
    click_on 'Create Alliance'
    # Missing all fields
    click_on 'Create Alliance'
    expect(page).to have_content("Name can't be blank")
    expect(page).to have_content("Tag can't be blank")
    expect(page).to have_content("Description can't be blank")
    expect(page).to have_content("Server can't be blank")

    # Invalid tag (not 4 chars, not alphanumeric)
    fill_in 'Alliance Name', with: 'Bad Tag Alliance'
    fill_in 'Tag', with: '12!'
    fill_in 'Description', with: 'Oops'
    fill_in 'Server', with: '12345'
    click_on 'Create Alliance'
    expect(page).to have_content('Tag must be 4 alphanumeric characters')

    # Now test invalid server values with a valid tag
    fill_in 'Alliance Name', with: 'Valid Alliance', fill_options: { clear: :backspace }
    fill_in 'Tag', with: 'B4D1', fill_options: { clear: :backspace }
    fill_in 'Description', with: 'Valid description', fill_options: { clear: :backspace }
    fill_in 'Server', with: 'abc', fill_options: { clear: :backspace }
    click_on 'Create Alliance'
    expect(page).to have_content('Server is invalid')

    fill_in 'Alliance Name', with: 'Valid Alliance', fill_options: { clear: :backspace }
    fill_in 'Tag', with: 'B4D1', fill_options: { clear: :backspace }
    fill_in 'Description', with: 'Valid description', fill_options: { clear: :backspace }
    fill_in 'Server', with: '12abc', fill_options: { clear: :backspace }
    click_on 'Create Alliance'
    expect(page).to have_content('Server is invalid')

    # Create another user to test duplicate tag
    other_user = create(:user, username: 'leader2', display_name: 'Leader Two', email: 'leader2@example.com', password: 'password123', password_confirmation: 'password123')
    Alliance.create!(name: 'Other', tag: 'ZZZZ', description: 'Other alliance', server: '123', admin: other_user)

    fill_in 'Alliance Name', with: 'Valid Alliance', fill_options: { clear: :backspace }
    fill_in 'Tag', with: 'ZZZZ', fill_options: { clear: :backspace }
    fill_in 'Description', with: 'Valid description', fill_options: { clear: :backspace }
    fill_in 'Server', with: '12345', fill_options: { clear: :backspace }
    click_on 'Create Alliance'
    expect(page).to have_content('Tag has already been taken')
  end

  it 'redirects with an alert when user already belongs to an alliance' do
    # First create an alliance for the user
    click_on 'Create Alliance'
    fill_in 'Alliance Name', with: 'First Alliance'
    fill_in 'Tag', with: 'A1B2'
    fill_in 'Description', with: 'First alliance description'
    fill_in 'Server', with: '12345'
    click_on 'Create Alliance'

    # Try to create another alliance
    visit new_alliance_path
    expect(page).to have_current_path('/dashboard')
    expect(page).to have_content('You already belong to an alliance.')
  end

  it 'redirects with an alert when trying to create a new alliance through POST request while already belonging to an alliance' do
    # First create an alliance for the user
    click_on 'Create Alliance'
    fill_in 'Alliance Name', with: 'First Alliance'
    fill_in 'Tag', with: 'A1B2'
    fill_in 'Description', with: 'First alliance description'
    fill_in 'Server', with: '12345'
    click_on 'Create Alliance'

    # Try to create another alliance by making a direct POST request
    page.driver.post(alliances_path, {
      alliance: {
        name: 'Second Alliance',
        tag: 'C3D4',
        description: 'Second alliance description',
        server: '12345'
      }
    })

    # Follow the redirect
    visit dashboard_path

    expect(page).to have_current_path('/dashboard')
    expect(page).to have_content('You already belong to an alliance.')
    expect(page).not_to have_content('Second Alliance')
    expect(page).to have_content('First Alliance')
  end

  it 'redirects to dashboard with a message when trying to access dashboard without an alliance' do
    user = create(:user, username: 'noalliance', display_name: 'No Alliance', email: 'noalliance@example.com', password: 'password123', password_confirmation: 'password123', role: :user)
    # First logout to ensure clean session
    click_on 'Logout'
    visit root_path
    click_on 'Login'
    fill_in 'Username', with: 'noalliance'
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
    visit dashboard_path
    expect(page).to have_current_path(dashboard_path)
    expect(page).to have_content("You don't belong to an alliance yet.")
  end

  context 'when user is not logged in' do
    before do
      click_on 'Logout'
    end

    it 'redirects to root path with alert when trying to access alliance pages' do
      # Try to access new alliance page
      visit new_alliance_path
      expect(page).to have_current_path('/')
      expect(page).to have_content('You must be logged in to access this page.')

      # Try to access dashboard
      visit dashboard_path
      expect(page).to have_current_path('/')
      expect(page).to have_content('You must be logged in to access this page.')

      # Try to create an alliance through POST request
      page.driver.post(alliances_path, {
        alliance: {
          name: 'Test Alliance',
          tag: 'TEST',
          description: 'Test description',
          server: '12345'
        }
      })

      # Follow the redirect
      visit root_path

      expect(page).to have_current_path('/')
      expect(page).to have_content('You must be logged in to access this page.')
    end
  end
end
