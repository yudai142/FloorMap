class AddDeviceInfoToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :device_identifier, :string
    add_column :sessions, :user_name, :string
    add_index :sessions, :device_identifier
  end
end
