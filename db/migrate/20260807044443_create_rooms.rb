class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :name, null: false
      t.text :description
      t.references :user, null: false, foreign_key: true
    end
  end
end
