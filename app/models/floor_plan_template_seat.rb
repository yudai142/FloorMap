class FloorPlanTemplateSeat < ApplicationRecord
  belongs_to :floor_plan_template

  validates :position_x, :position_y, presence: true, numericality: true
  validates :seat_type, presence: true
  validate :unique_position_within_template

  enum :seat_type, { regular: "regular", accessible: "accessible", vip: "vip" }

  def canvas_json
    { id: id, label: "S#{id}", x: position_x, y: position_y, occupied: false, occupant_name: "不明", seat_type: seat_type }
  end

  def seat_attributes
    {
      position_x: position_x,
      position_y: position_y,
      seat_type: seat_type
    }.merge(Seat.grid_position_for(position_x: position_x, position_y: position_y))
  end

  private

  def unique_position_within_template
    return if position_x.blank? || position_y.blank? || floor_plan_template_id.blank?

    existing = FloorPlanTemplateSeat.where(floor_plan_template_id: floor_plan_template_id, position_x: position_x, position_y: position_y)
    existing = existing.where.not(id: id) if persisted?
    errors.add(:base, "この座標には既に座席があります") if existing.exists?
  end
end
