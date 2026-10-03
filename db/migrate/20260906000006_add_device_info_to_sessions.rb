class AddDeviceInfoToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :device_identifier, :string, if_not_exists: true
    add_column :sessions, :user_name, :string, if_not_exists: true
    add_index :sessions, :device_identifier, if_not_exists: true
  end
end
