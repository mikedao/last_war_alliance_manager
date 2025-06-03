require 'rails_helper'

RSpec.describe 'Home Page', type: :feature do
  it 'displays the app copy and sign up/login buttons in the navbar when not logged in' do
    visit root_path
    expect(page).to have_content('Welcome to Last War Alliance Manager')
    expect(page).to have_content('alliance leaders in Last War: Survival Game')
    expect(page).to have_selector('nav')
    within('nav') do
      expect(page).to have_link('Sign Up')
      expect(page).to have_button('Login')
    end
  end
end
