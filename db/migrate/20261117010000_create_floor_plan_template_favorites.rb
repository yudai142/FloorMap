class CreateFloorPlanTemplateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :floor_plan_template_favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :floor_plan_template, null: false, foreign_key: true

      t.timestamps
    end

    add_index :floor_plan_template_favorites, [ :user_id, :floor_plan_template_id ],
              unique: true, name: "index_template_favorites_on_user_and_template"
  end
end
