class CreateFloorPlanTemplateSeats < ActiveRecord::Migration[8.1]
  def change
    create_table :floor_plan_template_seats do |t|
      t.references :floor_plan_template, null: false, foreign_key: true
      t.float :position_x, null: false
      t.float :position_y, null: false
      t.string :seat_type, null: false, default: "regular"

      t.timestamps
    end

    add_index :floor_plan_template_seats, [ :floor_plan_template_id, :position_x, :position_y ],
              unique: true, name: "index_template_seats_on_template_and_position"
  end
end
