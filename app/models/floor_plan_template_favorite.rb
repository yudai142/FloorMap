class FloorPlanTemplateFavorite < ApplicationRecord
  belongs_to :user
  belongs_to :floor_plan_template

  validates :floor_plan_template_id, uniqueness: { scope: :user_id }
end
