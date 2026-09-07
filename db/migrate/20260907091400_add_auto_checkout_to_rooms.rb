class AddAutoCheckoutToRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :auto_checkout_enabled, :boolean, default: false, null: false
    add_column :rooms, :auto_checkout_time, :string
  end
end
