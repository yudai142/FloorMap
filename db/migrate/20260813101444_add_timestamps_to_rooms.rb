class AddTimestampsToRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :created_at, :datetime, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    add_column :rooms, :updated_at, :datetime, null: false, default: -> { 'CURRENT_TIMESTAMP' }
  end
end
