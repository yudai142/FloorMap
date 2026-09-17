class CreateFloorPlanTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :floor_plan_templates do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.jsonb :floor_plan_data, default: [], null: false
      t.boolean :is_public, default: false, null: false
      t.integer :usage_count, default: 0

      t.timestamps
    end

    add_index :floor_plan_templates, :user_id
    add_index :floor_plan_templates, :is_public
    add_index :floor_plan_templates, [:user_id, :is_public]
  end
end
