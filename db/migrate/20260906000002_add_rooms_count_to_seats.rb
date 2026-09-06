class AddRoomsCountToSeats < ActiveRecord::Migration[8.1]
  def change
    add_column :seats, :rooms_count, :integer, default: 0
  end
end
