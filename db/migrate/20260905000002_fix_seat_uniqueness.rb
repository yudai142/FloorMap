class FixSeatUniqueness < ActiveRecord::Migration[8.0]
  def change
    remove_index :seats, [:row_number, :column_number, :room_id], if_exists: true
    add_index :seats, [:position_x, :position_y, :room_id], unique: true
  end
end
