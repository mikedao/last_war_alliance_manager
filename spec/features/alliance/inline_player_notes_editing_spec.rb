require 'rails_helper'

RSpec.describe 'Inline Player Notes Editing', type: :feature do
  include ActionView::RecordIdentifier

  let(:admin_user) { create(:user, role: :alliance_admin) }
  let!(:alliance) { create(:alliance, admin: admin_user) }
  let!(:player) { create(:player, alliance: alliance, notes: "Initial notes.") }

  before do
    visit login_path
    fill_in 'Username', with: admin_user.username
    fill_in 'Password', with: 'password123'
    click_on 'Log In'
    visit alliance_players_path(alliance)
  end

  it 'allows inline editing by clicking on the notes text', js: true do
    # Debug: print the page HTML at the start
    puts "INITIAL PAGE HTML:\n#{page.html}"
    
    # Check for content instead of the frame selector
    expect(page).to have_content("Initial notes.")

    # 1. The notes text should be visible, but not the form
    expect(page).to have_content("Initial notes.")
    expect(page).not_to have_field("player_notes")

    # 2. Click on the notes text to trigger the edit form
    click_on "Initial notes."

    # Wait for the form field to appear (workaround for Turbo async)
    expect(page).to have_field("player_notes", with: "Initial notes.")
    expect(page).to have_button("Save")
    expect(page).to have_link("Cancel")

    # 4. Update the notes and save
    fill_in "player_notes", with: "Updated notes."
    click_button "Save"

    # Wait for the content to update
    expect(page).to have_content("Updated notes.")
    expect(page).not_to have_button("Save")

    # 6. Verify the change is persisted
    expect(player.reload.notes).to eq("Updated notes.")
  end

  it 'allows cancelling an edit', js: true do
    # Check for content instead of the frame selector
    expect(page).to have_content("Initial notes.")

    # Click on the notes text
    click_on "Initial notes."

    # Wait for the form field to appear
    expect(page).to have_field("player_notes", with: "Initial notes.")
    expect(page).to have_button("Save")

    # Click "Cancel"
    click_link "Cancel"

    # Wait for the content to revert
    expect(page).to have_content("Initial notes.")
    expect(page).not_to have_button("Save")
  end
end 
