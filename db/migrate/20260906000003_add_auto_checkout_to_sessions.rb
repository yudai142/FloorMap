class AddAutoCheckoutToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :auto_checkout_at, :datetime
    add_column :sessions, :checkout_timer_minutes, :integer, default: 60
  end
end
