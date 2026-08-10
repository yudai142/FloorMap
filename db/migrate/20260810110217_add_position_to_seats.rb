class AddPositionToSeats < ActiveRecord::Migration[8.1]
  def change
    add_column :seats, :position_x, :float
    add_column :seats, :position_y, :float
  end
end
