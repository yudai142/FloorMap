class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :room, null: false, foreign_key: true
      t.string :notification_type
      t.text :title
      t.text :body
      t.datetime :read_at

      t.timestamps
    end
  end
end
