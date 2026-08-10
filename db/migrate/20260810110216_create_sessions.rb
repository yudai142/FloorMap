class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :seat, null: false, foreign_key: true
      t.datetime :check_in_time, null: false
      t.datetime :check_out_time
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :sessions, [ :user_id, :status ]
    add_index :sessions, [ :seat_id, :status ]
    add_index :sessions, :status
  end
end
