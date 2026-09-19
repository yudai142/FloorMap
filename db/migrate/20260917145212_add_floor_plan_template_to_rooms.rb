class AddFloorPlanTemplateToRooms < ActiveRecord::Migration[8.1]
  def change
    add_reference :rooms, :floor_plan_template, foreign_key: true, null: true
  end
end
