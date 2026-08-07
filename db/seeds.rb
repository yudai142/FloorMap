User.delete_all
Room.delete_all
RoomPermission.delete_all

# テストユーザー作成
admin_user = User.create!(
  email: 'admin@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :admin
)
puts "✓ Admin user created: #{admin_user.email}"

manager_users = [
  { email: 'manager1@example.com', name: 'Manager 1' },
  { email: 'manager2@example.com', name: 'Manager 2' }
].map do |attrs|
  User.create!(
    email: attrs[:email],
    password: 'password123',
    password_confirmation: 'password123',
    role: :manager
  )
end
puts "✓ Manager users created: #{manager_users.map(&:email).join(', ')}"

regular_users = [
  { email: 'user1@example.com', name: 'User 1' },
  { email: 'user2@example.com', name: 'User 2' },
  { email: 'user3@example.com', name: 'User 3' }
].map do |attrs|
  User.create!(
    email: attrs[:email],
    password: 'password123',
    password_confirmation: 'password123',
    role: :user
  )
end
puts "✓ Regular users created: #{regular_users.map(&:email).join(', ')}"

# テストルーム作成
rooms = [
  { name: 'もくもく会 - 渋谷', description: 'プログラミングもくもく会 渋谷会場', user: manager_users[0] },
  { name: 'デザイン勉強会 - 新宿', description: 'デザイン技法の勉強会', user: manager_users[1] },
  { name: 'チーム会議室A', description: 'エンジニアチームの定期会議', user: manager_users[0] },
  { name: 'カフェスペース', description: 'カジュアルな集まり用', user: regular_users[0] }
].map do |attrs|
  Room.create!(
    name: attrs[:name],
    description: attrs[:description],
    user: attrs[:user]
  )
end
puts "✓ Rooms created: #{rooms.map(&:name).join(', ')}"

# テスト権限設定
# もくもく会 - 渋谷: manager1が所有、user1-user3に権限付与
RoomPermission.create!(
  room: rooms[0],
  user: regular_users[0],
  permission_type: :edit
)
RoomPermission.create!(
  room: rooms[0],
  user: regular_users[1],
  permission_type: :view
)
RoomPermission.create!(
  room: rooms[0],
  user: regular_users[2],
  permission_type: :view
)

# デザイン勉強会 - 新宿: manager2が所有、user1-user2に権限付与
RoomPermission.create!(
  room: rooms[1],
  user: regular_users[0],
  permission_type: :manage
)
RoomPermission.create!(
  room: rooms[1],
  user: regular_users[1],
  permission_type: :edit
)

# チーム会議室A: manager1が所有、manager2に権限付与
RoomPermission.create!(
  room: rooms[2],
  user: manager_users[1],
  permission_type: :edit
)

puts "✓ Room permissions created"
puts "\n=== Seeding completed ==="
puts "\nテストアカウント:"
puts "  Admin: admin@example.com / password123"
puts "  Manager: manager1@example.com / password123"
puts "  Manager: manager2@example.com / password123"
puts "  User: user1@example.com / password123"
puts "  User: user2@example.com / password123"
puts "  User: user3@example.com / password123"
