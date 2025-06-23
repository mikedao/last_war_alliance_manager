# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create an alliance admin user
alliance_admin = User.find_or_create_by!(username: 'alliance_admin') do |user|
  user.display_name = 'Alliance Admin'
  user.email = 'admin@alliance.com'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = :alliance_admin
end

# Create an alliance for the admin
alliance = Alliance.find_or_create_by!(admin: alliance_admin) do |alliance|
  alliance.name = 'The Legend of EZ'
  alliance.tag = 'EZLG'
  alliance.description = 'A powerful alliance focused on strategic warfare and team coordination.'
  alliance.server = '1023'
end

# Create an alliance manager user
alliance_manager = User.find_or_create_by!(username: 'alliance_manager') do |user|
  user.display_name = 'Alliance Manager'
  user.email = 'manager@alliance.com'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = :alliance_manager
  user.alliance = alliance
end

# Ensure the manager is associated with the alliance
alliance_manager.update!(alliance: alliance) unless alliance_manager.alliance == alliance

# Create players with mixed active/inactive statuses
players_data = [
  { username: 'DragonSlayer', rank: 'R5', level: 95, active: true, notes: 'Top performer, excellent in raids' },
  { username: 'ShadowKnight', rank: 'R4', level: 87, active: true, notes: 'Great defensive player' },
  { username: 'FireMage', rank: 'R3', level: 78, active: true, notes: 'Strong offensive capabilities' },
  { username: 'IceQueen', rank: 'R4', level: 82, active: false, notes: 'Inactive due to personal reasons' },
  { username: 'ThunderBolt', rank: 'R2', level: 65, active: true, notes: 'New recruit, showing promise' },
  { username: 'StealthNinja', rank: 'R3', level: 71, active: true, notes: 'Excellent scout and intelligence gatherer' },
  { username: 'GoldenEagle', rank: 'R5', level: 89, active: false, notes: 'Temporarily inactive - work commitments' },
  { username: 'SilverWolf', rank: 'R1', level: 45, active: true, notes: 'Junior member, learning quickly' },
  { username: 'CrimsonBlade', rank: 'R4', level: 83, active: true, notes: 'Veteran player, reliable in battles' },
  { username: 'MysticSage', rank: 'R3', level: 76, active: false, notes: 'Inactive - taking a break from the game' }
]

players_data.each do |player_attrs|
  Player.find_or_create_by!(username: player_attrs[:username], alliance: alliance) do |player|
    player.rank = player_attrs[:rank]
    player.level = player_attrs[:level]
    player.active = player_attrs[:active]
    player.notes = player_attrs[:notes]
  end
end

puts "Seed data created successfully!"
puts "Alliance Admin: #{alliance_admin.username} (password: password123)"
puts "Alliance Manager: #{alliance_manager.username} (password: password123)"
puts "Alliance: #{alliance.name} (#{alliance.tag})"
puts "Players created: #{Player.where(alliance: alliance).count}"
puts "Active players: #{Player.where(alliance: alliance, active: true).count}"
puts "Inactive players: #{Player.where(alliance: alliance, active: false).count}"
