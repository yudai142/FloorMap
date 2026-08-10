class CreateRoomPermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :room_permissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :room, null: false, foreign_key: true
      t.integer :permission_type, null: false
    end

    add_index :room_permissions, [ :user_id, :room_id ], unique: true
  end
end
