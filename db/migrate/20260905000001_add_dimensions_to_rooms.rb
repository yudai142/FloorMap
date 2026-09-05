class AddDimensionsToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :width, :integer, default: 1000
    add_column :rooms, :height, :integer, default: 700
  end
end
