class AddAutoCheckoutToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :auto_checkout_at, :datetime, if_not_exists: true
    add_column :sessions, :checkout_timer_minutes, :integer, default: 60, if_not_exists: true
  end
end
