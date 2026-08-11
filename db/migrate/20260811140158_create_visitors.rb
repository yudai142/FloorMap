class CreateVisitors < ActiveRecord::Migration[8.1]
  def change
    create_table :visitors do |t|
      t.string :session_id, null: false
      t.string :nickname, null: false

      t.timestamps
    end

    add_index :visitors, :session_id, unique: true
    add_index :visitors, :created_at
  end
end
