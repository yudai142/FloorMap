class AddFloorPlanDataToRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :floor_plan_data, :jsonb, default: [], null: false
  end
end
