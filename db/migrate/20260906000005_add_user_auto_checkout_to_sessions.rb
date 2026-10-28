class AddUserAutoCheckoutToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :user_auto_checkout_enabled, :boolean, default: false, if_not_exists: true
    add_column :sessions, :user_auto_checkout_time, :datetime, if_not_exists: true
  end
end
