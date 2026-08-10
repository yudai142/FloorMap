class CreateSeats < ActiveRecord::Migration[8.1]
  def change
    create_table :seats do |t|
      t.references :room, null: false, foreign_key: true
      t.integer :row_number, null: false
      t.integer :column_number, null: false
      t.string :seat_type, null: false, default: 'regular'

      t.timestamps
    end

    add_index :seats, [ :room_id, :row_number, :column_number ], unique: true
  end
end
