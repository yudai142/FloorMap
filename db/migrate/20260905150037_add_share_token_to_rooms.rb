class AddShareTokenToRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :share_token, :string
    add_index :rooms, :share_token, unique: true
  end
end
