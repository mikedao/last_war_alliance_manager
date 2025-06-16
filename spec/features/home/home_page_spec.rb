require 'rails_helper'

RSpec.describe 'Home Page', type: :feature do
  it 'displays the app copy and sign up/login buttons in the navbar when not logged in' do
    visit root_path

    expect(page).to have_content('Welcome to Last War Alliance Manager')
    expect(page).to have_content('alliance leaders in Last War: Survival Game')
    expect(page).to have_selector('nav')
    within('nav') do
      expect(page).to have_selector(:link_or_button, 'Sign Up')
      expect(page).to have_selector(:link_or_button, 'Login')
    end
  end

  it 'displays the app title in the navbar and links to home' do
    visit root_path

    within('nav') do
      expect(page).to have_selector(:link_or_button, 'Last War Alliance Manager')
    end

    # Test that clicking the title takes us back to home
    click_link 'Last War Alliance Manager'
    expect(page).to have_current_path('/')
  end
end
