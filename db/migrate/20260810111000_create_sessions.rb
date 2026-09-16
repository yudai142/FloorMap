class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :user, foreign_key: true
      t.references :visitor, foreign_key: true
      t.references :seat, null: false, foreign_key: true, index: { name: "index_sessions_on_seat_id" }
      t.datetime :check_in_time, null: false
      t.datetime :check_out_time
      t.integer :checkout_timer_minutes, default: 60
      t.string :status, default: "active", null: false
      t.datetime :auto_checkout_at
      t.string :device_identifier
      t.string :user_name
      t.boolean :user_auto_checkout_enabled, default: false
      t.datetime :user_auto_checkout_time

      t.timestamps
    end

    add_index :sessions, [:seat_id, :status], name: "index_sessions_on_seat_id_and_status"
    add_index :sessions, [:user_id, :status], name: "index_sessions_on_user_id_and_status"
    add_index :sessions, :status
    add_index :sessions, :device_identifier
  end
end
