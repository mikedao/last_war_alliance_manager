require 'rails_helper'

RSpec.feature 'Inline Player Notes Editing', type: :feature do
  let(:alliance_admin) { create(:user, role: :alliance_admin) }
  let!(:alliance) { create(:alliance, admin: alliance_admin, tag: 'TEST') }
  let!(:player) { create(:player, alliance: alliance, username: 'TestPlayer', notes: 'Initial notes') }

  before do
    visit login_path
    fill_in 'Username', with: alliance_admin.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
  end

  it 'allows inline editing by clicking on the notes text' do
    visit players_path
    
    # Click on the notes text to start editing
    within("tr[data-player-username='TestPlayer']") do
      click_on 'Initial notes'
    end
    
    # Should show the edit form
    expect(page).to have_field('player[notes]', with: 'Initial notes')
    expect(page).to have_button('Save')
    expect(page).to have_link('Cancel')
  end

  it 'allows cancelling an edit' do
    visit players_path
    
    # Click on the notes text to start editing
    within("tr[data-player-username='TestPlayer']") do
      click_on 'Initial notes'
    end
    
    # Cancel the edit
    click_on 'Cancel'
    
    # Should be back to the display view
    expect(page).to have_content('Initial notes')
    expect(page).not_to have_field('player[notes]')
  end
end
